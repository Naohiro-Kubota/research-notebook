#!/bin/sh
set -eu

if [ -z "${SIMULATOR_UDID:-}" ]; then
  printf '%s\n' 'SIMULATOR_UDID is required. Run xcrun simctl list devices available and choose an iPad Simulator UDID.' >&2
  exit 2
fi

cd "$(dirname "$0")/.."

exec xcodebuild \
  -project ResearchNotebook.xcodeproj \
  -scheme ResearchNotebook \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
  -derivedDataPath "$PWD/DerivedData" \
  CODE_SIGNING_ALLOWED=NO \
  test
