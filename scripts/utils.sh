#!/bin/bash

# Install required dependencies
install_dependencies() {
    echo "Installing dependencies..."
    if ! command -v grpcurl &> /dev/null; then
        curl -L https://github.com/fullstorydev/grpcurl/releases/download/v1.8.7/grpcurl_1.8.7_linux_x86_64.tar.gz | tar xz
        sudo mv grpcurl /usr/local/bin/
    fi
    
    if ! command -v jq &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y jq
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
    
    # Get release information using curl
    local RESPONSE=$(curl -s -H "Authorization: token $token" -H "Accept: application/vnd.github.v3+json" "$API_URL")
    
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

# Upload archive to modules.wippy.ai
upload_archive() {
    local module_id="$1"
    echo "Uploading archive to modules.wippy.ai"
    
    grpcurl -plaintext \
      -d '{
        "module_id": "'$module_id'",
        "archive_content": "'$(base64 -w 0 source.zip)'",
        "format": "ARCHIVE_FORMAT_ZIP"
      }' \
      modules.wippy.ai:443 \
      registry.module.v1.UploadService/UploadArchive
    
    # Clean up
    rm source.zip
} 