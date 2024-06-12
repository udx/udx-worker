#!/bin/bash
set -e

# Function to handle nice logs
nice_logs() {
  local message=$1
  local level=$2
  case $level in
    info)
      echo -e "\e[32m$message\e[0m"
      ;;
    success)
      echo -e "\e[34m$message\e[0m"
      ;;
    *)
      echo -e "$message"
      ;;
  esac
}

# Load all modules in the modules directory
modules_dir="/home/udx-worker/bin-modules/modules"
if [ -d "$modules_dir" ]; then
  for module_file in "$modules_dir"/*.sh; do
    [ -e "$module_file" ] || continue
    bash "$module_file"
  done
else
  echo "Directory $modules_dir does not exist."
  exit 1
fi

# Use the colors in logs
nice_logs "Here you go, welcome to UDX Worker Container." "info"
nice_logs "..."

sleep 1

nice_logs "Init the environment..." "info"
nice_logs "..."

# Call the EnvironmentController from the modules environment
nice_logs "Do the configuration..." "info"

# Placeholder for environment controller logic
echo -e "\e[32mEnvironment configuration logic goes here.\e[0m"

nice_logs "..."
sleep 1

nice_logs "The worker has started successfully." "success"

# Check if the first argument is "project_init"
if [ "$1" == "project_init" ]; then
  if [ $# -lt 4 ]; then
    echo "Not enough arguments for project_init"
    exit 1
  fi
  # Placeholder for project initialization logic
  echo "Initializing project with arguments: $2, $3"
fi
