#!/bin/sh

#  ci_post_xcodebuild.sh
#  VerseByVerse
#
#  Runs in Xcode Cloud after archiving, before the build is handed off to
#  TestFlight distribution. Apple's Xcode Cloud looks for
#  TestFlight/WhatToTest.<locale>.txt at the repo root at this point and, if
#  present, uses its contents as the build's "What to Test" notes — no
#  App Store Connect API call needed.
#
#  We only have something worth testers reading on tag-triggered builds
#  (see ci_pre_xcodebuild.sh for the same $CI_TAG gate). release-please
#  already wrote a curated changelog section for this exact version as part
#  of the Release PR that produced the tag, so we just lift that section out
#  of CHANGELOG.md instead of re-deriving it from raw git log.

set -e

cd "$CI_PRIMARY_REPOSITORY_PATH"

TAG="${CI_TAG:-}"
if [ -z "$TAG" ]; then
    echo "ci_post_xcodebuild: not a tag-triggered build, skipping What to Test generation"
    exit 0
fi

VERSION=$(tr -d '[:space:]' < version.txt)
CHANGELOG="CHANGELOG.md"
OUT_DIR="TestFlight"
OUT_FILE="$OUT_DIR/WhatToTest.en-US.txt"
# Apple's commonly documented limit for beta build "What to Test" text.
MAX_CHARS=4000

if [ ! -f "$CHANGELOG" ]; then
    echo "ci_post_xcodebuild: $CHANGELOG not found, skipping What to Test generation"
    exit 0
fi

SECTION=$(awk -v ver="$VERSION" '
    /^## \[/ {
        if (insection) exit
        if (index($0, "## [" ver "]") == 1) { insection = 1; next }
        next
    }
    insection { print }
' "$CHANGELOG")

# Tidy release-please markdown into plain text suitable for TestFlight:
# "### Features" -> "Features:", drop the trailing "([sha](url))" commit
# links, "* " bullets -> "- ", and collapse repeated blank lines.
NOTES=$(printf '%s\n' "$SECTION" \
    | sed -E 's/^### (.*)/\1:/' \
    | sed -E 's/ *\(\[[0-9a-f]+\]\([^)]+\)\)//' \
    | sed -E 's/^\* /- /' \
    | awk 'NF{blank=0} !NF{blank++} blank<2')

NOTES=$(printf '%s' "$NOTES" | sed -e '1{/^$/d;}' -e '${/^$/d;}')

if [ -z "$NOTES" ]; then
    echo "ci_post_xcodebuild: no CHANGELOG.md section for version '$VERSION', writing fallback notes"
    NOTES="Build $VERSION ($TAG). See CHANGELOG.md for full details."
fi

if [ ${#NOTES} -gt $MAX_CHARS ]; then
    echo "ci_post_xcodebuild: notes exceed ${MAX_CHARS} chars, truncating"
    NOTES=$(printf '%s' "$NOTES" | cut -c1-$((MAX_CHARS - 1)))
fi

mkdir -p "$OUT_DIR"
printf '%s\n' "$NOTES" > "$OUT_FILE"

echo "ci_post_xcodebuild: wrote $(wc -c < "$OUT_FILE" | tr -d '[:space:]') bytes to $OUT_FILE"
echo "--- What to Test preview ---"
cat "$OUT_FILE"
echo "----------------------------"
