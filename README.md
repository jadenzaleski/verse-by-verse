# Verse By Verse

A local-first iOS app for Bible verse memorization: add passages, practice them with typing and recitation activities, and let FSRS-6 spaced repetition (running fully on-device) schedule your reviews. All user data lives in a SwiftData store on the device — no accounts, no login. The only server dependency is a slim [Bible-text proxy](https://github.com/jadenzaleski/verse-by-verse-api).

## Development

Open `VerseByVerse.xcodeproj`, pick a simulator, `Cmd+R`. Use the `VerseByVerse (local)` scheme against a locally running API. Unit tests live in `VerseByVerseTests` (Swift Testing). See `CLAUDE.md` for architecture notes.

## Releasing

Versioning is automated with [release-please](https://github.com/googleapis/release-please) on `master`, driven by [Conventional Commits](https://www.conventionalcommits.org/). Merging the open Release PR cuts a `vX.Y.Z-beta.N` prerelease (external TestFlight); adding a `Release-As: X.Y.Z` commit graduates it to a stable `vX.Y.Z` (App Store). Plain pushes to `master` build to internal TestFlight via Xcode Cloud.
