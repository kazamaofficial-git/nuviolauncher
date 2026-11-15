#!/usr/bin/env bash
# Signs an APK with the release keystore when the signing secrets exist.
# Without them the APK stays debug-signed (installable, but it cannot update a release-signed install).
#
# Usage: scripts/ci/sign-apk.sh <in.apk> <out.apk>
# Env:   ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD
set -euo pipefail

in_apk="$1"
out_apk="$2"

if [ -z "${ANDROID_KEYSTORE_BASE64:-}" ]; then
  echo "::warning::No release keystore configured; shipping a debug-signed APK."
  cp "$in_apk" "$out_apk"
  exit 0
fi

keystore="$(mktemp --suffix=.jks)"
trap 'rm -f "$keystore"' EXIT
echo "$ANDROID_KEYSTORE_BASE64" | base64 -d > "$keystore"

apksigner="$(ls -1 "${ANDROID_HOME:?}"/build-tools/*/apksigner | sort -V | tail -n 1)"
KS_PASS="$ANDROID_KEYSTORE_PASSWORD" KEY_PASS="${ANDROID_KEY_PASSWORD:-$ANDROID_KEYSTORE_PASSWORD}" \
  "$apksigner" sign \
    --ks "$keystore" \
    --ks-key-alias "$ANDROID_KEY_ALIAS" \
    --ks-pass env:KS_PASS \
    --key-pass env:KEY_PASS \
    --out "$out_apk" "$in_apk"
"$apksigner" verify --verbose "$out_apk"
