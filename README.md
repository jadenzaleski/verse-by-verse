# Verse By Verse

[![deploy-web](https://github.com/jadenzaleski/verse-by-verse/actions/workflows/deploy-web.yml/badge.svg)](https://github.com/jadenzaleski/verse-by-verse/actions/workflows/deploy-web.yml)
[![release-please](https://github.com/jadenzaleski/verse-by-verse/actions/workflows/release-please.yml/badge.svg)](https://github.com/jadenzaleski/verse-by-verse/actions/workflows/release-please.yml)

A local-first iOS app for Bible verse memorization: add passages, practice them with typing and recitation activities, and let FSRS-6 spaced repetition (running fully on-device) schedule your reviews. All user data lives in a SwiftData store on the device. The only server dependency is a slim Bible-text proxy.

## Development

Open `VerseByVerse.xcodeproj`, pick a simulator, `Cmd+R`. Use the `VerseByVerse (local)` scheme against a locally running API. Unit tests live in `VerseByVerseTests` (Swift Testing). The app's data layer is SwiftData (local-first) and review scheduling uses the [`swift-fsrs`](https://github.com/open-spaced-repetition/swift-fsrs) package.

## Website

The marketing and privacy site lives in `web/`: plain HTML with Tailwind CSS and daisyUI, no framework. Requires Node 22.

```sh
cd web
npm install     # once
npm run dev     # watches src/input.css -> dist/style.css
python3 -m http.server 8000   # in a second terminal, then open http://localhost:8000
```

Changes under `web/` that reach `master` are published to GitHub Pages by `.github/workflows/deploy-web.yml`, which runs `npm run build` and copies an explicit list of files into the site. **If you add a new top-level file or folder to `web/`, add it to the "Assemble site" step**, or it will be missing from the published site.

## Releasing

Versioning is automated with [release-please](https://github.com/googleapis/release-please) on `master`, driven by [Conventional Commits](https://www.conventionalcommits.org/). Merging the open Release PR cuts a `vX.Y.Z-beta.N` prerelease (external TestFlight); adding a `Release-As: X.Y.Z` commit graduates it to a stable `vX.Y.Z` (App Store). Plain pushes to `master` build to internal TestFlight via Xcode Cloud.
