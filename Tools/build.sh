#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:-mac}"
CONFIGURATION="${CONFIGURATION:-Debug}"
case "$MODE" in
  mac) SCHEME=PresentInkMac; DESTINATION='platform=macOS' ;;
  ipad) SCHEME=PresentInkCompanion; DESTINATION='generic/platform=iOS' ;;
  simulator) SCHEME=PresentInkCompanion; DESTINATION='generic/platform=iOS Simulator' ;;
  *) echo 'Aufruf: Tools/build.sh [mac|ipad|simulator]' >&2; exit 2 ;;
esac
ARGS=()
if [[ "$MODE" == simulator ]]; then ARGS+=(CODE_SIGNING_ALLOWED=NO); fi
if [[ -n "${DEVELOPMENT_TEAM:-}" ]]; then ARGS+=("DEVELOPMENT_TEAM=$DEVELOPMENT_TEAM"); fi
xcodebuild -project "$ROOT/PresentInk.xcodeproj" -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" -destination "$DESTINATION" \
  -derivedDataPath "$ROOT/build/$MODE" "${ARGS[@]}" build
printf '\nBuild liegt unter: %s/build/%s/Build/Products\n' "$ROOT" "$MODE"
