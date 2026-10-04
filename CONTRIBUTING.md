# Contributing

Thanks for helping with Verse By Verse! Contributions are welcome.

## License of contributions

This project is proprietary (see [LICENSE](LICENSE)). By opening a pull request
you agree to the **Contributions** section of the license: you keep your
copyright, and you grant the project owner a perpetual, irrevocable license to
use your contribution, including in the App Store release. If you're not okay
with that, please don't submit.

## Getting started

1. Fork the repo and create a branch from `master`.
2. Open `VerseByVerse.xcodeproj`, pick a simulator, and press `Cmd+R`. Use the
   `VerseByVerse (local)` scheme if you're running the
   [API](https://github.com/jadenzaleski/verse-by-verse-api) locally.
3. Run the tests: `VerseByVerseTests` (Swift Testing), via Xcode or
   `xcodebuild test -scheme "VerseByVerse (debug)" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:VerseByVerseTests`.

## Website

The site is in `web/`; see the [Website section of the README](README.md#website)
for how to run it. It is published automatically when changes to `web/` reach
`master`.

## Before you open a PR

- Run `swiftformat .` and then `swiftlint`. Lint errors fail the build.
- Use [Conventional Commits](https://www.conventionalcommits.org/) for commit
  messages (`feat:`, `fix:`, `docs:`, …). Releases and the changelog are
  generated from them.
- Keep PRs focused, and add or update tests when you change behavior.
- Never commit secrets, and never log them. Verse text must not be stored
  locally beyond the existing cache (licensing).

## Reporting bugs and ideas

Open an issue with steps to reproduce, the iOS version, and the device or
simulator you used.
