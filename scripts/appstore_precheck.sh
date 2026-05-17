#!/usr/bin/env bash
# Quick checks before App Store / TestFlight upload.
# Run from repo root: ./scripts/appstore_precheck.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

echo "== App Store precheck (وش سلندر / com.kareem.washslender) =="
echo ""

OK=1
PLIST="$ROOT/ios/Runner/GoogleService-Info.plist"
if [[ ! -f "$PLIST" ]]; then
  echo "[!] Missing: ios/Runner/GoogleService-Info.plist"
  echo "    Firebase Console → Project → add iOS app with bundle com.kareem.washslender"
  echo "    → download GoogleService-Info.plist → place in ios/Runner/"
  echo "    → open ios/Runner.xcworkspace in Xcode → drag file into Runner,"
  echo "       check 'Copy items', add to Runner target, verify 'Copy Bundle Resources'."
  echo ""
  OK=0
else
  echo "[✓] GoogleService-Info.plist present"
fi

if command -v pod &>/dev/null; then
  echo ">> pod install (ios/) …"
  (cd "$ROOT/ios" && pod install)
  echo "[✓] CocoaPods install finished"
else
  echo "[!] pod not in PATH — install CocoaPods or use Xcode’s environment"
  OK=0
fi

echo ""
if [[ "$OK" -eq 1 ]]; then
  echo "Next: create the app in App Store Connect (see chat), then:"
  echo "  ./scripts/build_ios_appstore_ipa.sh"
else
  echo "Fix the items above, then run this script again."
  exit 1
fi
