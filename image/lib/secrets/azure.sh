#!/bin/sh

# Function to resolve Azure secret
resolve_azure_secret() {
    local secret_url=$1
    local vault_name secret_name secret_value

    # Extract vault name and secret name from the URL
    vault_name=$(echo "$secret_url" | sed -n 's|https://\([^\.]*\)\.vault.azure.net.*|\1|p')
    secret_name=$(echo "$secret_url" | sed -n 's|.*/secrets/\([^/?]*\).*|\1|p')

    if [ -z "$vault_name" ] || [ -z "$secret_name" ]; then
        echo "[ERROR] Invalid Azure Key Vault URL: $secret_url"
        return 1
    fi

    # Retrieve the secret value using Azure CLI
    secret_value=$(az keyvault secret show --vault-name "$vault_name" --name "$secret_name" --query value -o tsv 2>/dev/null)

    if [ $? -ne 0 ] || [ -z "$secret_value" ]; then
        echo "[ERROR] Failed to retrieve secret from Azure Key Vault: $secret_url"
        return 1
    fi

    echo "$secret_value"
    return 0
}
