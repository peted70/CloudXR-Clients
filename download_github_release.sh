#!/bin/sh

set -eux

# Base URL for fetching releases
GITHUB_API_URL="https://api.github.com/repos/peted70/CloudXR-Clients/releases?per_page=100"
found_release=false

# Loop through all pages of releases
while [ "$GITHUB_API_URL" != "null" ]; do
  # Fetch the release metadata and save it to a file
  curl -H "Authorization: Bearer $GITHUB_PAT" -H "Accept: application/vnd.github+json" $GITHUB_API_URL \
      -o releases_info.json

  # Loop through each release on this page
  for release in $(jq -c '.[]' releases_info.json); do
    # Check if this release has a matching asset
    asset_id=$(echo $release | jq -r '.assets[] | select(.name | startswith("CloudXR-SDK") and endswith(".zip")) | .id')

    # If a matching asset is found, download it
    if [ -n "$asset_id" ]; then
      echo "Found asset with ID $asset_id in release: $(echo $release | jq -r '.name')"
      found_release=true
      asset_url=$(echo $release | jq -r ".assets[] | select(.id == $asset_id) | .url")
      asset_name=$(echo $release | jq -r ".assets[] | select(.id == $asset_id) | .name")
      break 2  # Break out of both loops
    fi
  done

  # If no matching asset was found, get the next page URL
  GITHUB_API_URL=$(jq -r '. | if .links.next then .links.next else "null" end' releases_info.json)
done

# If no release was found, exit with an error
if [ "$found_release" = false ]; then
  echo "Error: No release found with the required asset"
  exit 1
fi

echo "Downloading asset with ID $asset_id and saving it as $asset_name"

# Download the asset and save it with its original name
curl -L -H "Accept: application/octet-stream" -H "Authorization: Bearer $GITHUB_PAT" \
     -H "X-GitHub-Api-Version: 2022-11-28" \
     "$asset_url" \
     --output "$asset_name"

# Verify the downloaded file
ls -lh "$asset_name"
file "$asset_name"
head -n 20 "$asset_name"
