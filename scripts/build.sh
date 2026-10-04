#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

exec xcodebuild \
  -project ResearchNotebook.xcodeproj \
  -scheme ResearchNotebook \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$PWD/DerivedData" \
  CODE_SIGNING_ALLOWED=NO \
  build
