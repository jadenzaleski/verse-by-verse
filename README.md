# Verse By Verse

## Releasing

Versioning is automated with [release-please](https://github.com/googleapis/release-please) on `master`, driven by [Conventional Commits](https://www.conventionalcommits.org/). Merging the open Release PR cuts a `vX.Y.Z-beta.N` prerelease (external TestFlight); adding a `Release-As: X.Y.Z` commit graduates it to a stable `vX.Y.Z` (App Store). Plain pushes to `master` build to internal TestFlight via Xcode Cloud.
