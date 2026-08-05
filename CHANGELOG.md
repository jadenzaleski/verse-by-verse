# Changelog

## [0.1.0-beta.1](https://github.com/jadenzaleski/verse-by-verse-app/compare/v0.1.0-beta.0...v0.1.0-beta.1) (2026-08-05)


### Bug Fixes

* Fixed several release issues and restrucuted workflows. ([a8af149](https://github.com/jadenzaleski/verse-by-verse-app/commit/a8af14937980c1e0638becb9fcb27b297d159f5a))

## [0.1.0-beta.0](https://github.com/jadenzaleski/verse-by-verse-app/compare/v0.0.0-beta.0...v0.1.0-beta.0) (2026-08-05)


### ⚠ BREAKING CHANGES

* schema reshaped around Verse; existing local stores are incompatible (wipe and reinstall — no external users).
* requests no longer send X-App-Key (matches the API dropping the check).
* no accounts — all data is device-local until the CloudKit phase.
* user data is no longer read from or written to the VBV API; existing server-side data is not migrated (fresh start).

### Features

* add on-device FSRS-6 engine with py-fsrs parity fixtures ([0eb3898](https://github.com/jadenzaleski/verse-by-verse-app/commit/0eb38989c5eb7414befe851f2f57be2521d13298))
* Added a GENERAL section in the SettingsView and Allowed the users the clear the Cache. ([c44008d](https://github.com/jadenzaleski/verse-by-verse-app/commit/c44008d152e36dfd66f7a89d776277f39f8790eb))
* Added better linking and made bible text a different text. ([5a81e1f](https://github.com/jadenzaleski/verse-by-verse-app/commit/5a81e1fef4d06115efd02f369f80ef8f634017cf))
* Added delete option in passage. ([21b2aae](https://github.com/jadenzaleski/verse-by-verse-app/commit/21b2aaea513ab82ecfa9f2d5696ed778fd878769))
* Added DueText to standardize the due time. ([0600d8e](https://github.com/jadenzaleski/verse-by-verse-app/commit/0600d8ea86aa46e03853f0a922fab222827e6746))
* Added network monitor and better verse passge adding. ([7951d3d](https://github.com/jadenzaleski/verse-by-verse-app/commit/7951d3d21407fa1e1acfc9f789798296ca767cc2))
* Added superscript verse numbers. ([a22664e](https://github.com/jadenzaleski/verse-by-verse-app/commit/a22664e64c730e10d8178d33dd51c39477186b77))
* Added VerseByVerseTests ([4883a29](https://github.com/jadenzaleski/verse-by-verse-app/commit/4883a2907ba1045bfb8538c273a525d5fee1e7b9))
* Attempt a healthcheck before letting the user log in. ([4396220](https://github.com/jadenzaleski/verse-by-verse-app/commit/43962203cbf474757e605838ae32e439ec81d97a))
* Changed the progress bar to show Memory Score and not past sessions. ([7230a55](https://github.com/jadenzaleski/verse-by-verse-app/commit/7230a55bdd5c031744bbafdb2280a572ed2e1849))
* Created DesignSystem for better handling of design values. Also fixed warnings. ([a1f1670](https://github.com/jadenzaleski/verse-by-verse-app/commit/a1f1670675be6c4a34a22f4b8c30bd429cc3a547))
* Implemented DesignSystem ([5c0d1f2](https://github.com/jadenzaleski/verse-by-verse-app/commit/5c0d1f2ce058581f65f73ff8f8e79a9cea93869e))
* remove accounts, login, and keychain — fully local app ([9336651](https://github.com/jadenzaleski/verse-by-verse-app/commit/933665172ab7d845d095a6871d588137728331dd))
* replace server-backed data layer with local SwiftData store ([ad166aa](https://github.com/jadenzaleski/verse-by-verse-app/commit/ad166aad25afb36a846e11398a67a039f3b992eb))
* Seperated out several common cards between passage and verses. This is also my first attempt at a long text card. ([f4f3229](https://github.com/jadenzaleski/verse-by-verse-app/commit/f4f322931c7cfacb85dc02ad7ccc717a7a8963e7))
* share logs via share sheet and enrich log format ([37a1988](https://github.com/jadenzaleski/verse-by-verse-app/commit/37a19884027588b5261f3cf4786f91018fab947a))
* show build channel and version in Developer view ([ca62d3c](https://github.com/jadenzaleski/verse-by-verse-app/commit/ca62d3ca31b073adb217569eec61318e43cc9c3c))
* show the passage reference at the end of each practice-session activity ([50cdbff](https://github.com/jadenzaleski/verse-by-verse-app/commit/50cdbff02ebb6c1dce388ce196efdd2bb39ba8f8))
* slim API client to Bible proxy with static app key ([15dce14](https://github.com/jadenzaleski/verse-by-verse-app/commit/15dce14a98f9004b4d1e41496a4e7d91c55d62de))
* tune FSRS for verses — stricter ratings, retention 0.95 ([91ce93c](https://github.com/jadenzaleski/verse-by-verse-app/commit/91ce93cc4d16b82bfd0cbb3ed829c4ac17d5af17))
* verse-level UI — Verses tab, verse detail with exact history ([a7dc1d1](https://github.com/jadenzaleski/verse-by-verse-app/commit/a7dc1d15675b5eca143df23f343b82f3e155a3c4))


### Bug Fixes

* cap verse-text cache at 14 days (licensing) ([a8e4508](https://github.com/jadenzaleski/verse-by-verse-app/commit/a8e4508c4915232dbf8a205a22f4f028fbf8506c))
* correct log ordering and tighten file size limits ([2a7101f](https://github.com/jadenzaleski/verse-by-verse-app/commit/2a7101f22fd5cb2e7fac084040c6ab2fb670a08d))
* Fixed hidden word rendering issues. ([055ee45](https://github.com/jadenzaleski/verse-by-verse-app/commit/055ee450ea343eb4229263961d1a891d080e2c02))
* Fixed issue where app would not show server was unreachable. ([0d6a309](https://github.com/jadenzaleski/verse-by-verse-app/commit/0d6a3096abb20251c24b27b06d65827f0ab5fd9b))
* Fixed issue where probe would not retry. ([2d9a4f1](https://github.com/jadenzaleski/verse-by-verse-app/commit/2d9a4f135a0446cf17b7ef630243b2d7b9fdc23a))
* Fixed UI long verse text issues. ([8229e61](https://github.com/jadenzaleski/verse-by-verse-app/commit/8229e618b0482831a209e024eb82817e21dc61df))
* hide Developer tools in production builds ([06d36c3](https://github.com/jadenzaleski/verse-by-verse-app/commit/06d36c3df8471781676ac80bd9437bb4a512be01))
* Ironing out NetwrokMonitor. ([3dc14e6](https://github.com/jadenzaleski/verse-by-verse-app/commit/3dc14e6c1b8f5abbca54dd3c3becc87ebe63da0a))
* Made settings button rounded and a sheet. ([97dbf81](https://github.com/jadenzaleski/verse-by-verse-app/commit/97dbf81e9ded256f161f71fc31897aa95ea61316))
* match health check to the slim API's response shape ([a46226f](https://github.com/jadenzaleski/verse-by-verse-app/commit/a46226febf2328f25aaec024f313a75bb1d831c1))
* Move logging behavior off MainActor, and make LogsView lazy load. ([2665fa1](https://github.com/jadenzaleski/verse-by-verse-app/commit/2665fa1e33c21190dc9a6c477b441063fd12d43f))
* Moved API URL and log level to config files only. ([f174a51](https://github.com/jadenzaleski/verse-by-verse-app/commit/f174a511d66d8bdebcc4fd5aa9f74e5affd1c329))
* Organized Views to smaller files. ([3a3e6b3](https://github.com/jadenzaleski/verse-by-verse-app/commit/3a3e6b37fe50457c8bd43a6c7f1ef73af579700d))
* select the real Montserrat italic face and scale the verse-number baseline offset ([a9f59ef](https://github.com/jadenzaleski/verse-by-verse-app/commit/a9f59ef6c248d01090338dc1ed19074037497955))


### Miscellaneous Chores

* target 0.1.0-beta.0 as first TestFlight release ([f323736](https://github.com/jadenzaleski/verse-by-verse-app/commit/f3237364f1d4fc549f98ad5d94c9dfb8c12de612))


### Code Refactoring

* make the Verse the FSRS card — passages become derived ([8a15f5c](https://github.com/jadenzaleski/verse-by-verse-app/commit/8a15f5c5aa9030abffe113b2ca5868688f36678d))
* remove app API key — server rate limiting only for now ([7aaa4ac](https://github.com/jadenzaleski/verse-by-verse-app/commit/7aaa4ac0d6894dadfdce0e7c432aaa2d586054c6))
