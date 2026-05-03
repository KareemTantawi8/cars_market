#!/usr/bin/env bash
# Builds a Google Play–ready App Bundle (AAB) with Dart obfuscation.
# Prerequisites:
#   1. android/key.properties (copy from key.properties.example; gitignored)
#   2. Keystore file path must match storeFile in key.properties (often android/app/upload-keystore.jks)
# Usage:
#   ./scripts/build_play_store_bundle.sh
#   ./scripts/build_play_store_bundle.sh --dart-define=API_BASE_URL=https://your.api/api/v1
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

KP="$ROOT/android/key.properties"
if [[ ! -f "$KP" ]]; then
  echo ""
  echo "  Missing: android/key.properties"
  echo "  1. Copy:  cp android/key.properties.example android/key.properties"
  echo "  2. Edit android/key.properties with your storePassword, keyPassword, keyAlias, storeFile."
  echo "  3. Put your .jks/.keystore where storeFile points (often android/app/upload-keystore.jks)."
  echo ""
  exit 1
fi

SYMS="$ROOT/build/app_symbols"
mkdir -p "$SYMS"

echo ">> flutter build appbundle --release --obfuscate --split-debug-info=$SYMS $@"
flutter build appbundle --release --obfuscate --split-debug-info="$SYMS" "$@"

AAB="$ROOT/build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "  Done."
echo "  Upload this file to Play Console: $AAB"
echo "  Keep build/app_symbols/ private — needed to deobfuscate crash stacks."
echo ""
