# Verse By Verse

A local-first iOS app for Bible verse memorization: add passages, practice them with typing and recitation activities, and let FSRS-6 spaced repetition (running fully on-device) schedule your reviews. All user data lives in a SwiftData store on the device — no accounts, no login. The only server dependency is a slim [Bible-text proxy](https://github.com/jadenzaleski/verse-by-verse-api).

## Development

Open `VerseByVerse.xcodeproj`, pick a simulator, `Cmd+R`. Use the `VerseByVerse (local)` scheme against a locally running API. Unit tests live in `VerseByVerseTests` (Swift Testing). See `CLAUDE.md` for architecture notes.

## Releasing

Versioning is automated with [release-please](https://github.com/googleapis/release-please) on `master`, driven by [Conventional Commits](https://www.conventionalcommits.org/). Merging the open Release PR cuts a `vX.Y.Z-beta.N` prerelease (external TestFlight); adding a `Release-As: X.Y.Z` commit graduates it to a stable `vX.Y.Z` (App Store). Plain pushes to `master` build to internal TestFlight via Xcode Cloud.

## Road to 1.0

Target: **App Store by end of 2026.** Apple slows App Store Connect around Dec 23–27, so the working deadline is **Fri Dec 18**, with submission aimed at **Dec 12** to leave room for a rejection cycle.

Detailed rationale for every item lives in `docs/release-readiness.md` and `docs/apple-standards-audit.md` (both local-only, not in git).

### Blockers — cannot submit without these

- [x] `PrivacyInfo.xcprivacy` declaring required-reason API usage (UserDefaults, file timestamps)
- [ ] Confirm the two privacy-manifest reason codes against Xcode's plist-editor dropdown
- [x] Privacy policy + support pages published
- [ ] Privacy policy: add third-party Bible text provider section
- [ ] Privacy policy: add data-deletion section (deleting the app removes everything; no server copy)
- [ ] Document Bible text licensing terms for every shipped translation — app redistribution rights, caching window, required attribution, verse-count limits
- [ ] Implement provider usage reporting (`fums_tokens` are currently decoded and discarded in `BibleSelectionResponse` → `toDomain()`; reporting belongs server-side)
- [ ] Stand up and verify the production API host; confirm TLS, `/health`, and monitoring
- [ ] Cut a throwaway stable tag to exercise the production URL path before the real release
- [ ] App Store Connect: App Privacy questionnaire (separate from the privacy manifest)
- [ ] App Store Connect: age rating questionnaire
- [ ] App Store Connect: content rights declaration (third-party Bible text → yes)
- [ ] Screenshots for every shipped device class (6.9" iPhone; 13" iPad only if iPad ships)
- [ ] Listing metadata: description, subtitle, keywords, promo text, What's New, copyright
- [ ] Review notes: no account needed, mic/speech is on-device and optional, Bible text rights summary
- [x] Replace the `AppLinks.supportEmail` placeholder with the real address

### Quality — shouldn't submit without these

- [ ] Remove `fatalError` from `AppModelContainer.make()` — a corrupt store is currently an unrecoverable launch crash with total data loss
- [ ] Remove `fatalError` from `AppFunctions.apiBaseURL` and the `FileManager…first!` force-unwraps
- [ ] Bundle the Bible books metadata as an app resource — a first launch with no network currently leaves the Add screen permanently disabled with no explanation
- [ ] Stop the microphone on backgrounding (observe `scenePhase`; `onDisappear` doesn't fire)
- [ ] Handle `AVAudioSession` interruptions and route changes; stop killing the user's music
- [ ] Add retry affordances on network failure (`SessionView` dead-ends; use `ContentUnavailableView`)
- [ ] VoiceOver for the practice flow — keystrokes go through an invisible `TextField` and correctness is conveyed by color alone
- [ ] Don't rely on color alone for correct/incorrect, due/overdue, and score tiers
- [ ] Verify the Developer screen is absent from a Release archive
- [ ] Fix `BibleStore`'s shared `state` so metadata and selection fetches stop clobbering each other
- [ ] Map `NetworkError` in `APIService.mapError` (currently degrades to `.unknown`, silently stalling reachability)
- [ ] Set the project-level deployment target to match the targets (still 26.1 while both targets are 27.0)
- [x] In-app Contact Support + Share Diagnostics + Website + Privacy Policy rows
- [ ] Commit the Xcode Cloud product manifest (`xcshareddata/xcodecloud/`)
- [ ] Add App Attest to the API and client
- [ ] Raise API rate limits and return `429` + `Retry-After` so App Review's concentrated IPs don't get throttled

### Decisions with deadlines

- [ ] **Oct 17** — App Attest in v1, or ship with compensating controls?
- [ ] **Oct 24** — iPad: invest in `NavigationSplitView` + adaptive layouts, or set `TARGETED_DEVICE_FAMILY = 1` and ship iPhone-only?
- [ ] **Oct 31** — Licensing resolved, or fall back to public-domain translations only (KJV, ASV, WEB, YLT, Douay-Rheims)?
- [ ] Confirm the iOS 27.0 minimum is intentional, and reconcile it with the "iOS 26 or later" claim on the website
- [ ] Settle one app name: site says "Verse by Verse", `CFBundleDisplayName` is "Verse", product is "VerseByVerse"

### Strongly recommended, not blocking

- [ ] Local notifications for due reviews — a spaced-repetition app that never tells you a review is due has a structural retention problem
- [ ] Data export (JSON via `ShareLink`) — the only copy of a user's history is one device's backup
- [ ] Drop the splash screen; warm caches in the background instead
- [ ] Undo via `modelContainer(isUndoEnabled:)` — every destructive dialog currently says "can't be undone"

### Explicitly deferred to 1.1+

Swift 6 language mode and the build-settings hardening pass; localization / String Catalog; the `Cache`-as-actor and logging concurrency refactors; style, file-layout and naming cleanup; App Intents, Widgets, Spotlight, Live Activities; broader test coverage.
