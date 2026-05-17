#!/usr/bin/env bash
# Builds an App Store / TestFlight–ready IPA via Flutter + Xcode signing.
#
# Prerequisites (macOS + Xcode):
#   - Xcode installed and signed-in Apple ID with access to team 66MLL878HK
#   - App registered in App Store Connect with bundle id com.kareem.washslender
#   - CocoaPods: cd ios && pod install
#
# Usage:
#   ./scripts/build_ios_appstore_ipa.sh
#   ./scripts/build_ios_appstore_ipa.sh --dart-define=API_BASE_URL=https://your.api/api/v1
set -euo pipefail

# CocoaPods / Ruby on some Macs errors with ASCII-8BIT unless UTF-8 is set.
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

OPTS_PLIST="$ROOT/ios/ExportOptions-appstore.plist"
if [[ ! -f "$OPTS_PLIST" ]]; then
  echo "Missing $OPTS_PLIST"
  exit 1
fi

echo ">> flutter build ipa --release --export-options-plist=\"$OPTS_PLIST\" $@"
flutter build ipa --release --export-options-plist="$OPTS_PLIST" "$@"

IPA_DIR="$ROOT/build/ios/ipa"
echo ""
echo "  Done."
echo "  Upload the .ipa via Transporter, or Xcode Organizer, or:"
echo "    xcrun altool --upload-app -f \"$IPA_DIR\"/*.ipa --apiKey YOUR_API_KEY --apiIssuer YOUR_ISSUER_ID"
echo ""
