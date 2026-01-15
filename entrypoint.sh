#!/bin/sh
set -e

echo "Starting WPFactory Product Updater action"

# Inputs (GitHub Actions format)
API_URL="$INPUT_API_URL"
PRODUCT_ID="$INPUT_PRODUCT_ID"
PRODUCT_FILENAME="$INPUT_PRODUCT_FILENAME"
API_TOKEN="$INPUT_API_TOKEN"
TOKEN_HEADER_KEY="$INPUT_TOKEN_HEADER_KEY"

# GitHub context
REPO="$GITHUB_REPOSITORY"
TAG="$GITHUB_REF_NAME"

FILENAME_FULL="${PRODUCT_FILENAME}.zip"

echo "Repository: $REPO"
echo "Tag: $TAG"
echo "Final filename: $FILENAME_FULL"

# -----------------------------
# Download tag zip from GitHub
# -----------------------------
echo "Downloading tag $TAG from $REPO"

GITHUB_RESPONSE=$(eval "curl -vLJ \
  -H 'Authorization: token $API_TOKEN' \
  'https://api.github.com/repos/$REPO/zipball/$TAG' \
  --output '$FILENAME_FULL'")

# -----------------------------
# Validate zip
# -----------------------------
echo "Validating zip file"

ls -lh "$FILENAME_FULL"

if ! file "$FILENAME_FULL" | grep -q "Zip archive"; then
  echo "Error: downloaded file is not a zip"
  exit 1
fi

# -----------------------------
# Unzip and normalize structure
# -----------------------------
unzip -q "$FILENAME_FULL" || exit 1
rm "$FILENAME_FULL"

FOLDERS_COUNT=$(ls -d */ | wc -l | tr -d ' ')
if [ "$FOLDERS_COUNT" -ne 1 ]; then
  echo "Error: expected exactly one root folder, got $FOLDERS_COUNT"
  exit 1
fi

ROOT_DIR=$(ls -d */)
ROOT_DIR=${ROOT_DIR%/}

echo "Renaming root folder $ROOT_DIR to $PRODUCT_FILENAME"
mv "$ROOT_DIR" "$PRODUCT_FILENAME"

# -----------------------------
# Repack zip
# -----------------------------
zip -qr "$FILENAME_FULL" "$PRODUCT_FILENAME"

echo "Zip rebuilt successfully:"
ls -lh "$FILENAME_FULL"

# -----------------------------
# Upload to WP REST API
# -----------------------------
UPLOAD_URL="${API_URL}?product_id=${PRODUCT_ID}"

echo "Uploading to $UPLOAD_URL"

curl -f \
  -H "${TOKEN_HEADER_KEY}: ${API_TOKEN}" \
  -F "file=@${FILENAME_FULL}" \
  "$UPLOAD_URL"

echo "Upload completed successfully"