#!/bin/sh

set -eux

# Fetch the release metadata and save it to a file
curl -H "Authorization: Bearer $GITHUB_PAT" -H "Accept: application/vnd.github+json" $GITHUB_API_URL \
    -o release_info.json

# Extract the asset ID
asset_id=$(jq -r '.assets[] | select(.name == "CloudXR-SDK_4_0_0.zip") | .id' release_info.json)

# Check if the asset ID is empty
if [ -z "$asset_id" ]; then
    echo "Error: No asset ID found"
    exit 1
fi

echo "Downloading asset with ID $asset_id"

# Download the asset
curl -L -H "Accept: application/octet-stream" -H "Authorization: Bearer $GITHUB_PAT" \
     -H "X-GitHub-Api-Version: 2022-11-28" \
     "https://api.github.com/repos/peted70/CloudXR-Clients/releases/assets/$asset_id" \
     --output CloudXR-SDK_4_0_0.zip

# Verify the downloaded file
ls -lh CloudXR-SDK_4_0_0.zip
file CloudXR-SDK_4_0_0.zip
head -n 20 CloudXR-SDK_4_0_0.zip
