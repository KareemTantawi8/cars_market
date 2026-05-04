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
  echo "  1. Create keystore + key.properties:  ./scripts/create_play_store_keystore.sh"
  echo "     (or copy android/key.properties.example → android/key.properties and add your .jks path + passwords.)"
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
