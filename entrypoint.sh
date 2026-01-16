#!/bin/sh
set -e

echo "=== WPFactory Product Updater Action ==="

# -----------------------------
# Inputs
# -----------------------------
API_URL="$INPUT_API_URL"
PRODUCT_ID="$INPUT_PRODUCT_ID"
PRODUCT_FILENAME="$INPUT_PRODUCT_FILENAME"
API_TOKEN="$INPUT_API_TOKEN"
TOKEN_HEADER_KEY="$INPUT_TOKEN_HEADER_KEY"
GITHUB_TOKEN="$INPUT_GITHUB_TOKEN"

# -----------------------------
# GitHub context
# -----------------------------
REPO="$GITHUB_REPOSITORY"
TAG="$GITHUB_REF_NAME"

ZIP_NAME="${PRODUCT_FILENAME}.zip"

echo "Repo: $REPO"
echo "Tag: $TAG"
echo "Zip name: $ZIP_NAME"

# -----------------------------
# Download tag archive from GitHub API
# -----------------------------
echo "Downloading tag archive from GitHub API..."
curl -fLJ \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$REPO/zipball/$TAG" \
  -o "$ZIP_NAME"

# -----------------------------
# Inspect downloaded zip
# -----------------------------
echo "Downloaded zip file:"
ls -lh "$ZIP_NAME"

echo "Zip contents (before processing):"
unzip -l "$ZIP_NAME"

echo "Validating zip..."
unzip -tq "$ZIP_NAME" >/dev/null

# -----------------------------
# Unzip and normalize structure
# -----------------------------
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

# -----------------------------
# Rebuild zip
# -----------------------------
echo "Rebuilding zip..."
zip -qr "$ZIP_NAME" "$PRODUCT_FILENAME"

echo "Final zip file:"
ls -lh "$ZIP_NAME"

#echo "Zip contents (final):"
#unzip -l "$ZIP_NAME"

# -----------------------------
# Upload to WP REST API
# -----------------------------
echo "Uploading to WP REST API: $API_URL"

RESPONSE=$(curl -sS -A "Mozilla/5.0 (GitHub-Action)" \
  -H "${TOKEN_HEADER_KEY}: ${API_TOKEN}" \
  -H "Accept: application/json" \
  -F "file=@${ZIP_NAME}" \
  -F "product_id=${PRODUCT_ID}" \
  "$API_URL")

# **Set GitHub Action output**
echo "response=$RESPONSE" >> $GITHUB_OUTPUT
