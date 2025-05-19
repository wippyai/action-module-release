#!/bin/bash

# Exit on error
set -e

# Source utility functions
source "$(dirname "$0")/utils.sh"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --repository)
      REPOSITORY="$2"
      shift 2
      ;;
    --tag)
      TAG="$2"
      shift 2
      ;;
    --token)
      TOKEN="$2"
      shift 2
      ;;
    --module-id)
      MODULE_ID="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [ -z "$REPOSITORY" ] || [ -z "$TAG" ] || [ -z "$TOKEN" ] || [ -z "$MODULE_ID" ]; then
  echo "Usage: $0 --repository <repo> --tag <tag> --token <token> --module-id <module_id>"
  exit 1
fi

# Install dependencies
install_dependencies

# Get release information
RELEASE_INFO=$(get_release_info "$REPOSITORY" "$TAG" "$TOKEN")
RELEASE_URL=$(echo "$RELEASE_INFO" | jq -r '.html_url')
SOURCE_CODE_URL="https://github.com/$REPOSITORY/archive/refs/tags/$TAG.zip"

# Download and process source code
download_source_code "$SOURCE_CODE_URL"
upload_archive "$MODULE_ID"

# Output results
echo "Found release: $RELEASE_URL"
echo "Source code available at: $SOURCE_CODE_URL" 