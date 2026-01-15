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
# Download tag archive
# -----------------------------
echo "Downloading tag archive..."

#curl -fL \
#  "https://github.com/$REPO/archive/refs/tags/$TAG.zip" \
#  -o "$ZIP_NAME"

# Downloads the tag
GITHUB_RESPONSE=$(eval "curl -vLJ -H 'Authorization: token $TOKEN' 'https://api.github.com/repos/$REPO/zipball/$TAG' --output '$ZIP_NAME'")

# Renames zip archive folder
unzip $ZIP_NAME
rm $ZIP_NAME
cd */
mv ../{"${PWD##*/}",${PRODUCT_FILENAME}}
cd ..
zip -r $ZIP_NAME .

# -----------------------------
# Rebuild zip
# -----------------------------
echo "Rebuilding zip..."
zip -qr "$ZIP_NAME" "$PRODUCT_FILENAME"

echo "Final zip file:"
ls -lh "$ZIP_NAME"

echo "Zip contents (final):"
unzip -l "$ZIP_NAME"

# -----------------------------
# Upload to WP REST API
# -----------------------------
UPLOAD_URL="${API_URL}?product_id=${PRODUCT_ID}"

echo "Uploading to: $UPLOAD_URL"

curl -f \
  -H "${TOKEN_HEADER_KEY}: ${API_TOKEN}" \
  -F "file=@${ZIP_NAME}" \
  "$UPLOAD_URL"

echo "✅ Upload finished successfully"