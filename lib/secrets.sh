#!/bin/bash

# Include specific secret resolving scripts
source /usr/local/lib/secrets/azure.sh

# Function to resolve placeholders with environment variables
resolve_env_vars() {
    local value="$1"
    eval echo "$value"
}

# Function to redact sensitive URLs
redact_sensitive_urls() {
    echo "$1" | sed -E 's/(https:\/\/[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)\.([A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)([A-Za-z0-9\/_-]*)/\1.*********\2.*********\3/g'
}

# Function to fetch secrets and set them as environment variables
fetch_secrets() {
    echo "[INFO] Fetching secrets"
    
    WORKER_CONFIG="/home/$USER/.cd/configs/worker.yml"
    
    if [ ! -f "$WORKER_CONFIG" ]; then
        echo "[ERROR] YAML configuration file not found at $WORKER_CONFIG"
        return 1
    fi
    
    SECRETS_ENV_FILE="/tmp/secret_vars.sh"
    echo "# Secrets environment variables" > "$SECRETS_ENV_FILE"
    
    SECRETS_JSON=$(yq e -o=json '.config.workerSecrets' "$WORKER_CONFIG")
    echo "$SECRETS_JSON" | jq -c 'to_entries[]' | while read -r secret; do
        name=$(echo "$secret" | jq -r '.key')
        url=$(resolve_env_vars "$(echo "$secret" | jq -r '.value')")
        
        echo "[INFO] Resolved URL for $name: $(redact_sensitive_urls "$url")"
        
        case $url in
            https://*.vault.azure.net/*)
                if ! value=$(resolve_azure_secret "$url"); then
                    echo "[ERROR] Error resolving Azure secret for $name: $(redact_sensitive_urls "$url")" >&2
                    value=""
                fi
            ;;
            *)
                echo "[ERROR] Unsupported secret URL: $(redact_sensitive_urls "$url")" >&2
                value=""
            ;;
        esac
        
        if [ -n "$value" ]; then
            echo "export $name=\"$value\"" >> "$SECRETS_ENV_FILE"
            echo "[INFO] Secret $name resolved and set as environment variable." >&2
        else
            echo "[ERROR] Failed to resolve secret for $name" >&2
        fi
    done
    
    set -a
    if [ -f "$SECRETS_ENV_FILE" ]; then
        source "$SECRETS_ENV_FILE"
    else
        echo "[ERROR] Secrets environment file not found: $SECRETS_ENV_FILE"
        return 1
    fi
    set +a
}
