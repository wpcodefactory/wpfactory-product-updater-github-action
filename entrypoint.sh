#!/bin/sh
set -e

echo "=== WPFactory Product Updater Action ==="

# Inputs
API_URL="$INPUT_API_URL"
PRODUCT_ID="$INPUT_PRODUCT_ID"
PRODUCT_FILENAME="$INPUT_PRODUCT_FILENAME"
API_TOKEN="$INPUT_API_TOKEN"
TOKEN_HEADER_KEY="$INPUT_TOKEN_HEADER_KEY"

# GitHub context
REPO="$GITHUB_REPOSITORY"
TAG="$GITHUB_REF_NAME"

ZIP_NAME="${PRODUCT_FILENAME}.zip"

echo "Repo: $REPO"
echo "Tag: $TAG"
echo "Zip: $ZIP_NAME"

# --------------------------------------
# Download tag zip from GitHub
# --------------------------------------
echo "Downloading tag archive..."

curl -vLJ \
  -H "Authorization: token $API_TOKEN" \
  "https://api.github.com/repos/$REPO/zipball/$TAG" \
  -o "$ZIP_NAME"

# --------------------------------------
# Validate zip
# --------------------------------------
echo "Validating zip..."

ls -lh "$ZIP_NAME"

if ! file "$ZIP_NAME" | grep -q "Zip archive"; then
  echo "ERROR: Downloaded file is not a zip"
  echo "File contents:"
  cat "$ZIP_NAME"
  exit 1
fi

# --------------------------------------
# Unzip and normalize structure
# --------------------------------------
echo "Unzipping..."
unzip -q "$ZIP_NAME"
rm "$ZIP_NAME"

FOLDER_COUNT=$(ls -d */ | wc -l | tr -d ' ')
if [ "$FOLDER_COUNT" -ne 1 ]; then
  echo "ERROR: Expected exactly one root folder, got $FOLDER_COUNT"
  exit 1
fi

ROOT_DIR=$(ls -d */)
ROOT_DIR="${ROOT_DIR%/}"

echo "Renaming root folder '$ROOT_DIR' → '$PRODUCT_FILENAME'"
mv "$ROOT_DIR" "$PRODUCT_FILENAME"

# --------------------------------------
# Rebuild zip
# --------------------------------------
echo "Rebuilding zip..."
zip -qr "$ZIP_NAME" "$PRODUCT_FILENAME"

ls -lh "$ZIP_NAME"

# --------------------------------------
# Upload to WP REST API
# --------------------------------------
UPLOAD_URL="${API_URL}?product_id=${PRODUCT_ID}"

echo "Uploading to: $UPLOAD_URL"

curl -f \
  -H "${TOKEN_HEADER_KEY}: ${API_TOKEN}" \
  -F "file=@${ZIP_NAME}" \
  "$UPLOAD_URL"

echo "✅ Upload finished successfully"