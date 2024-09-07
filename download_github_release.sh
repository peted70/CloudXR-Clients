#!/bin/sh

set -eux

# Base URL for fetching releases
found_release=false

# Partial asset name to search for (e.g., match "CloudXR-SDK" regardless of version)
partial_asset_name="CloudXR-SDK"

# Fetch the latest release metadata and save it to a file
curl -H "Authorization: Bearer $GITHUB_SDK_PAT" -H "Accept: application/vnd.github+json" $GITHUB_API_URL \
  -o latest_release.json

# Print out the contents of the file for debug
echo "Contents of latest_release.json:"
cat latest_release.json

release=$(<latest_release.json)

# Extract the URL for the asset containing the partial name
asset_id=$(jq -r --arg partial_name "$partial_asset_name" \
    '.assets[] | select(.name | contains($partial_name)) | .id' \
    latest_release.json)

if [ -n "$asset_id" ]; then
  echo "Found asset with ID $asset_id in release: $(echo $release | jq -r '.name')"
  found_release=true
  
  asset_url=$(jq -r --arg asset_id "$asset_id" \
    '.assets[] | select(.id == ($asset_id | tonumber)) | .url' \
    latest_release.json)

  asset_name=$(jq -r --arg asset_id "$asset_id"\
    '.assets[] | select(.id == ($asset_id | tonumber)) | .name' \
    latest_release.json)
fi

# If no release was found, exit with an error
if [ "$found_release" = false ]; then
  echo "Error: No release found with the required asset"
  exit 1
fi

echo "Downloading asset with ID $asset_id and saving it as $asset_name"

# Download the asset and save it with its original name
curl -L -H "Accept: application/octet-stream" -H "Authorization: Bearer $GITHUB_SDK_PAT" \
     -H "X-GitHub-Api-Version: 2022-11-28" \
     "$asset_url" \
     --output "$asset_name"

export SDK_FILENAME=$asset_name

# Verify the downloaded file
ls -lh "$asset_name"
file "$asset_name"
head -n 20 "$asset_name"
