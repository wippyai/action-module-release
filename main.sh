#!/bin/bash

# Exit on error
set -e

# Install required dependencies
install_dependencies() {
    echo "Installing dependencies..."
    if ! command -v jq &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y jq
    fi
    
    if ! command -v docker &> /dev/null; then
        echo "::error::Docker is required but not installed. Please install Docker first." >&2
        exit 1
    fi
}

# Get release information from GitHub
get_release_info() {
    local repository="$1"
    local tag="$2"
    local token="$3"
    
    # Split repository into owner and repo
    IFS='/' read -r OWNER REPO <<< "$repository"
    
    # GitHub API endpoint
    local API_URL="https://api.github.com/repos/$OWNER/$REPO/releases/tags/$tag"
    
    # Prepare headers
    local HEADERS=("-H" "Accept: application/vnd.github.v3+json")
    if [ -n "$token" ]; then
        HEADERS+=("-H" "Authorization: token $token")
    fi
    
    # Get release information using curl
    local RESPONSE=$(curl -s "${HEADERS[@]}" "$API_URL")
    
    # Check if release exists
    if echo "$RESPONSE" | jq -e '.message == "Not Found"' > /dev/null; then
        echo "::error::Release $tag not found in $repository" >&2
        exit 1
    fi
    
    echo "$RESPONSE"
}

# Download source code
download_source_code() {
    local source_url="$1"
    echo "Downloading source code from $source_url"
    curl -L -o source.zip "$source_url"
}

# Clone module-registry-proto repository
clone_proto_repo() {
    # Repository is currently private but will be made public in the future
    echo "Cloning module-registry-proto repository..."
    if [ ! -d "proto" ]; then
        git clone git@github.com:wippyai/module-registry-proto.git proto
        if [ $? -ne 0 ]; then
            echo "::error::Failed to clone module-registry-proto repository. Make sure you have SSH access to GitHub." >&2
            exit 1
        fi
    else
        echo "proto directory already exists, skipping clone"
    fi
}

# Upload archive to modules.wippy.ai
upload_archive() {
    local module_id="$1"
    local tag="$2"
    local username="$3"
    local password="$4"
    echo "Uploading archive to modules.wippy.ai"
    
    # Debug: Print module ID and archive size
    echo "Debug: Uploading archive for module ID: $module_id"
    echo "Debug: Archive size: $(stat -c %s source.zip) bytes"
    
    # Build and run the upload tool in Docker
    docker build -t upload-tool . > /dev/null
    docker run --rm \
        -v "$(pwd)/source.zip:/app/source.zip" \
        -e "USERNAME=$username" \
        -e "PASSWORD=$password" \
        upload-tool "$module_id" "$tag" /app/source.zip "$username" "$password"
    
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo "::error::Failed to upload archive. Exit code: $exit_code" >&2
        exit 1
    fi
    
    # Clean up
    rm source.zip
    rm -rf proto
}

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
    --username)
      USERNAME="$2"
      shift 2
      ;;
    --password)
      PASSWORD="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [ -z "$REPOSITORY" ] || [ -z "$TAG" ] || [ -z "$MODULE_ID" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
  echo "Usage: $0 --repository <repo> --tag <tag> [--token <token>] --module-id <module_id> --username <username> --password <password>"
  exit 1
fi

# Install dependencies
install_dependencies

# Clone module-registry-proto repository
clone_proto_repo

# Get release information
if [ -n "$TOKEN" ]; then
    RELEASE_INFO=$(get_release_info "$REPOSITORY" "$TAG" "$TOKEN")
else
    RELEASE_INFO=$(get_release_info "$REPOSITORY" "$TAG")
fi
RELEASE_URL=$(echo "$RELEASE_INFO" | jq -r '.html_url')
SOURCE_CODE_URL="https://github.com/$REPOSITORY/archive/refs/tags/$TAG.zip"

# Download and process source code
download_source_code "$SOURCE_CODE_URL"
upload_archive "$MODULE_ID" "$TAG" "$USERNAME" "$PASSWORD"

# Output results
echo "Found release: $RELEASE_URL"
echo "Source code available at: $SOURCE_CODE_URL" 