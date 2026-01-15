#!/bin/sh
set -e

API_URL="$INPUT_API_URL"
PRODUCT_ID="$INPUT_PRODUCT_ID"
API_TOKEN="$INPUT_API_TOKEN"
TOKEN_HEADER_KEY="$INPUT_TOKEN_HEADER_KEY"
PRODUCT_FILENAME="$INPUT_PRODUCT_FILENAME"

REPO="$GITHUB_REPOSITORY"
TAG="$GITHUB_REF_NAME"

ZIP_NAME="${PRODUCT_FILENAME}.zip"
TMP_DIR="$(mktemp -d)"

echo "Downloading tag $TAG from $REPO"

# Download tag zipball (GitHub auto-generated)
curl -L \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$REPO/zipball/$TAG" \
  -o "$TMP_DIR/source.zip"

cd "$TMP_DIR"

# Unzip source
unzip source.zip
rm source.zip

# GitHub zipball always creates a single root folder
SRC_DIR="$(ls -d */ | head -n 1)"

# Rename root folder
mv "$SRC_DIR" "$PRODUCT_FILENAME"

# Re-zip with correct name + root folder
zip -r "$ZIP_NAME" "$PRODUCT_FILENAME"

echo "Uploading $ZIP_NAME to API"

curl -f -X POST \
  -H "$TOKEN_HEADER_KEY: $API_TOKEN" \
  -F "product_id=$PRODUCT_ID" \
  -F "file=@$TMP_DIR/$ZIP_NAME" \
  "$API_URL"