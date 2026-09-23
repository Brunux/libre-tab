# Security — Libre Tab

## Reporting a vulnerability

Please open a private security advisory on GitHub
(<https://github.com/Brunux/libre-tab/security/advisories/new>) rather than
a public issue. Include the app version, platform, and steps or a file that
shows the problem.

## Security model

Libre Tab is an offline app with no account and no server.

- **No network.** The Android release build requests no `INTERNET`
  permission (only `RECORD_AUDIO`); iOS has no App Transport Security
  exceptions and no URL schemes. There is no analytics, crash reporting or
  ad SDK.
- **Data stays in the app's sandbox:** a SQLite database (songs, setlists)
  and preferences. Nothing is secret, so it isn't encrypted beyond the
  operating system's own storage protection; the phone's own backups
  (iCloud, Google) may include it, as described in [PRIVACY.md](PRIVACY.md).
- **Untrusted input** is anything that comes from outside: song files and
  `.zip` exports opened from other apps or picked with Open file/Import,
  text shared from other apps, and photos for camera import. Every path is
  size-limited before parsing and every parser has been timed against
  crafted input (below).
- **Permissions:** microphone (tuner only, while the tuner is on screen),
  camera (only for "Take a photo"). Photos are chosen through the system
  picker, which needs no permission and only shares the photos picked; the
  app deletes its copy after reading it.

## Audit — September 2026

A review of the whole app: data leaving the device, file and share
handling, zip import, parsers, database, permissions and exported
components, dependencies, signing and repository hygiene.

### Fixed

| Issue | Risk | Fix |
|---|---|---|
| Chord patterns like `\[([^\]]+)\]` backtracked quadratically on text with many unmatched `[` (100k took minutes) | A crafted song file could freeze the app | Patterns stop at the next `[` (linear) |
| Tab-line and section-label patterns backtracked quadratically on long runs of spaces (13 s on 20k spaces) | Same | Rewritten so each run of spaces is read once |
| Merging a chord line into its lyric rebuilt the string per chord (quadratic) | Same, on very long lines | Single left-to-right pass |
| Files opened from other apps were read whole before the size check (Android and iOS) | Memory exhaustion from a huge file | Size checked first; Android reads at most the limit |
| Android accepted `file://` URIs in "Open with"/"Share to" | Another app could make Libre Tab open its own private files (e.g. its database) in the editor | Only `content://` URIs are accepted; the `file` scheme was removed from the intent filter |
| No size limits on song files, imports and zips | Memory exhaustion, "zip bombs" | Song files ≤ 256 KB; imports ≤ 32 MB; zips ≤ 5,000 songs and ≤ 64 MB unpacked, checked from the zip directory before unpacking, oversized entries skipped |
| Privacy statement said data is stored "only on your phone" | Inaccurate: phone backups include app data | Wording corrected |

`test/security/hostile_input_test.dart` runs every parser on crafted input
up to the maximum song size and fails if any takes over 2 seconds;
`test/features/library/songbook_archive_test.dart` covers the zip limits.

### Checked, no issue

- SQL: all queries are typed Drift queries or bound parameters; full-text
  search input is reduced to letters and digits before it reaches FTS5.
- Exported components: only `MainActivity` (needed for "Open with" and
  "Share to") and the system-protected AndroidX profile receiver. The
  image-picker and share file providers are not exported and grant access
  per file only.
- Zip import never writes entries to disk, so there is no path traversal
  ("zip slip").
- No secrets, keys, keystores, provisioning profiles or build output in the
  repository; signing files are in `.gitignore`. The app doesn't log song
  content.
- Dart packages: no advisories reported by `pub`.

### Open — to do before release

- **Android release signing** still uses the debug key
  (`android/app/build.gradle.kts`). Create an upload keystore, keep it and
  its passwords out of the repository (`key.properties` is ignored), and
  sign release builds with it; enable Play App Signing.
- **Supply chain.** Tesseract comes from JitPack (built from GitHub source,
  pinned to 4.9.0 and limited to its group in `android/build.gradle.kts`).
  Consider Gradle dependency verification. The bundled models are the
  official `tessdata_fast` files:
  - `eng.traineddata` SHA-256
    `7d4322bd2a7749724879683fc3912cb542f19906c83bcc1a52132556427170b2`
  - `spa.traineddata` SHA-256
    `6f2e04d02774a18f01bed44b1111f2cd7f3ba7ac9dc4373cd3f898a40ea6b464`
- **Residual:** a zip whose directory lies about entry sizes is still
  unpacked one entry at a time before its real size is checked; the 32 MB
  input limit bounds the damage to a failed import, not data loss (imports
  run in one transaction).
- The Android build has not yet been run on a device.
