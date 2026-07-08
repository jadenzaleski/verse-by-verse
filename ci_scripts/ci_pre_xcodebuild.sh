#!/bin/sh

#  ci_pre_xcodebuild.sh
#  VerseByVerse
#
#  Runs in Xcode Cloud before each build. Sets the marketing version from
#  release-please's version.txt and the build number from Xcode Cloud's
#  monotonic counter ($CI_BUILD_NUMBER).
#
#  - release-please owns version.txt (e.g. "1.2.3" or "1.2.3-beta01").
#  - The "-beta*" suffix is a git-tag/channel concept only; App Store marketing
#    versions must be plain "1.2.3", so we strip everything after the first "-".
#  - The build number must strictly increase on every upload, so it comes from
#    $CI_BUILD_NUMBER, never from the version.

set -e

RAW=$(tr -d '[:space:]' < "$CI_PRIMARY_REPOSITORY_PATH/version.txt")
MARKETING=$(printf '%s' "$RAW" | sed 's/-.*//')
BUILD="${CI_BUILD_NUMBER:-1}"

echo "ci_pre_xcodebuild: version.txt='$RAW' -> MARKETING_VERSION='$MARKETING', CFBundleVersion='$BUILD'"

cd "$CI_PRIMARY_REPOSITORY_PATH"
agvtool new-marketing-version "$MARKETING"
agvtool new-version -all "$BUILD"
