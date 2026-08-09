#!/usr/bin/env bash
#
# generate-keystore.sh — generate an Android upload keystore for BetBook and
# print the exact commands needed to configure GitHub Actions release signing.
#
# Creates a self-signed RSA-2048 keystore valid for ~27 years using keytool
# (bundled with the JDK). It then prints:
#   * the base64 command whose output goes into the KEYSTORE_BASE64 secret
#   * a reminder of the four GitHub secrets to add
#   * a sample android/key.properties for local release builds
#
# The keystore is written OUTSIDE the repo tree by default and must never be
# committed. Losing it means you can no longer ship updates signed with the
# same key, so back it up somewhere safe (a password manager works well).
#
# Usage:
#   scripts/generate-keystore.sh [output-file] [alias]
#
# Examples:
#   scripts/generate-keystore.sh
#   scripts/generate-keystore.sh "$HOME/betbook-upload.jks" upload

set -euo pipefail

OUT_FILE="${1:-$HOME/betbook-upload-keystore.jks}"
ALIAS="${2:-upload}"
VALIDITY_DAYS="${VALIDITY_DAYS:-10000}"

if ! command -v keytool >/dev/null 2>&1; then
  echo "ERROR: keytool not found on PATH. Install a JDK 17 (Temurin) and re-run." >&2
  exit 1
fi

if [[ -e "$OUT_FILE" ]]; then
  echo "ERROR: a keystore already exists at '$OUT_FILE'. Refusing to overwrite." >&2
  echo "       Delete it or pass a different output path." >&2
  exit 1
fi

echo "==> Generating upload keystore at: $OUT_FILE"
echo "    You will be prompted for a keystore password, a key password,"
echo "    and some optional identity fields (name/org can be left blank)."
echo

keytool -genkeypair \
  -v \
  -keystore "$OUT_FILE" \
  -alias "$ALIAS" \
  -keyalg RSA \
  -keysize 2048 \
  -validity "$VALIDITY_DAYS" \
  -storetype JKS

echo
echo "==> Keystore created."
echo
echo "1) Copy the base64 of the keystore into the KEYSTORE_BASE64 secret:"
echo
echo "     base64 -w0 \"$OUT_FILE\" > keystore.base64.txt      # Linux"
echo "     base64 \"$OUT_FILE\" | tr -d '\\n' > keystore.base64.txt  # macOS"
echo
echo "   Then copy the contents of keystore.base64.txt into the secret value."
echo
echo "2) Add these GitHub repository secrets"
echo "   (Settings -> Secrets and variables -> Actions -> New repository secret):"
echo
echo "     KEYSTORE_BASE64      the base64 blob from step 1"
echo "     KEYSTORE_PASSWORD    the keystore password you just chose"
echo "     KEY_PASSWORD         the key password you just chose"
echo "     KEY_ALIAS            $ALIAS"
echo
echo "3) For LOCAL release builds, create android/key.properties (git-ignored):"
echo
echo "     storeFile=$OUT_FILE"
echo "     storePassword=<your keystore password>"
echo "     keyAlias=$ALIAS"
echo "     keyPassword=<your key password>"
echo
echo "IMPORTANT: keep '$OUT_FILE' and its passwords safe and OUT of git."
echo "           If you lose them you cannot update the app with the same signature."
