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
#
#  - Also stamps the git commit SHA (always) and tag (only when this build was
#    triggered by a tag push) into Info.plist, so a running build can be traced
#    back to the exact GitHub commit/release — see AppFunctions.gitCommit/gitTag.
#
#  - Tag-triggered builds (both vX.Y.Z-beta.N and vX.Y.Z) all archive with the
#    same Release scheme — Xcode Cloud's tag condition only supports "begins
#    with", so it can't route beta vs. stable tags to different workflows. This
#    script does that differentiation instead: a tag containing "-beta" is the
#    beta channel (vbv-api-beta), any other tag is production (vbv-api-prod).
#    Branch-triggered (non-tag) builds are untouched and keep whatever
#    Debug.xcconfig already set — see AppFunctions.channel.

set -e

RAW=$(tr -d '[:space:]' < "$CI_PRIMARY_REPOSITORY_PATH/version.txt")
MARKETING=$(printf '%s' "$RAW" | sed 's/-.*//')
BUILD="${CI_BUILD_NUMBER:-1}"

echo "ci_pre_xcodebuild: version.txt='$RAW' -> MARKETING_VERSION='$MARKETING', CFBundleVersion='$BUILD'"

cd "$CI_PRIMARY_REPOSITORY_PATH"
agvtool new-marketing-version "$MARKETING"
agvtool new-version -all "$BUILD"

INFO_PLIST="VerseByVerse/Info.plist"
COMMIT="${CI_COMMIT:-unknown}"
TAG="${CI_TAG:-}"

echo "ci_pre_xcodebuild: GitCommit='$COMMIT', GitTag='$TAG'"

/usr/libexec/PlistBuddy -c "Delete :GitCommit" "$INFO_PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :GitCommit string $COMMIT" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Delete :GitTag" "$INFO_PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :GitTag string $TAG" "$INFO_PLIST"

if [ -n "$TAG" ]; then
    case "$TAG" in
        *-beta*)
            CHANNEL="beta"
            API_URL="https://vbv-api-beta.jadenzaleski.com"
            LOG_LEVEL=2
            ;;
        *)
            CHANNEL="production"
            API_URL="https://vbv-api-prod.jadenzaleski.com"
            LOG_LEVEL=2
            ;;
    esac

    echo "ci_pre_xcodebuild: tag-triggered -> BuildChannel='$CHANNEL', API_BASE_URL='$API_URL', DEFAULT_LOG_LEVEL='$LOG_LEVEL'"

    /usr/libexec/PlistBuddy -c "Delete :BuildChannel" "$INFO_PLIST" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :BuildChannel string $CHANNEL" "$INFO_PLIST"
    /usr/libexec/PlistBuddy -c "Set :API_BASE_URL $API_URL" "$INFO_PLIST"
    /usr/libexec/PlistBuddy -c "Set :DEFAULT_LOG_LEVEL $LOG_LEVEL" "$INFO_PLIST"
fi
