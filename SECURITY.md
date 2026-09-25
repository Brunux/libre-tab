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
- **Data stays in the app's sandbox:** a SQLite database (songs, setlists,
  play history: when each song was last opened and how often) and
  preferences. Nothing is secret, so it isn't encrypted beyond the
  operating system's own storage protection; the phone's own backups
  (iCloud, Google) may include it, as described in [PRIVACY.md](PRIVACY.md).
- **Untrusted input** is anything that comes from outside: song files and
  `.zip` exports opened from other apps or picked with Open file/Import,
  text shared from other apps or pasted from the clipboard (read only when
  Paste is tapped), and photos for camera import. Every path is
  size-limited before parsing and every parser has been timed against
  crafted input (below). Opening a file never navigates the app: Flutter's
  deep linking is off on both platforms and unknown routes go home.
- **Permissions:** microphone (tuner only, while the tuner is on screen),
  camera (only for "Take a photo"). Photos are chosen through the system
  picker, which needs no permission and only shares the photos picked; the
  app deletes its copy after reading it.

## Audit — 24 September 2026 (after the UI round)

A second full pass, focused on what changed since the first: the paste
button and other text entry, camera-import layout, the schema 4 upgrade
(play history, key backfill), the Setlists tab and auto-advance, the theme
and logo work, and the Android build now run on an emulator.

### Fixed

| Issue | Risk | Fix |
|---|---|---|
| Paste read the whole clipboard, and the text box, title, artist and setlist name had no length limit | A huge paste (tens of MB) froze the editor, which re-imports the text on every change | Paste refuses more than a song file may be (256 K characters) with a message; the text box stops at that, title / artist / setlist name at 200 characters |
| File names for Share and Export came from the title uncut | A very long title made the file name too long for the file system, so sharing failed | Cut to 100 characters (after removing `/ \ : * ? " < > \|` and control characters, so no path can leave the share folder) |
| Grouping photo words into lines compared each word with every line so far | A busy photo (thousands of words) slowed the layout with the square of the words | Compares only with the lines just above (linear); at most 5,000 words per photo are laid out |
| The schema 4 upgrade parsed every saved song to fill in its key in one step | If any song made the parser throw, the upgrade — and the songbook — would fail to open | Each song is read on its own; one that can't be read keeps no key |

`test/security/hostile_input_test.dart` now also lays out crafted photos
(20,000 words: one per line, one long line, all on one spot) within 2 s.

### Checked, no issue

- Android release manifest (merged): permissions `RECORD_AUDIO` only (plus
  the system's own `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`); exported:
  `MainActivity` and the `DUMP`-protected profile installer receiver, as
  before. File providers not exported. Flutter deep linking off
  (`flutter_deeplinking_enabled = false`).
- iOS `Info.plist`: no URL schemes, no App Transport Security exceptions,
  no iTunes file sharing, no background modes, deep linking off; purpose
  strings for microphone, camera and photos. Privacy manifest: no tracking;
  file timestamps `C617.1`, UserDefaults `CA92.1` (the clipboard isn't a
  required-reason API).
- SQL: every statement is a typed Drift query or uses bound parameters,
  including the upgrade's; the setlist search filters in Dart.
- No logging of song text, OCR words or file contents (a temporary OCR log
  used while tuning the Tesseract layout was removed before commit).
- No secrets, keystores or provisioning profiles tracked.
- Dart packages: no advisories or retracted versions from `pub`; the
  available updates are minor patches.
- Play history never leaves the database: not in exports or shares.
- Auto-advance and countdown timers are cancelled when the song view
  closes; nothing runs in the background.

### Noted

- Android `allowBackup` is on (the default), so the songbook and play
  history are in the phone's own backups, like the iPhone's iCloud backup;
  PRIVACY.md says so. Nothing in them is secret.

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
- The Android build has been run on an emulator (Android 13), not yet on a
  phone.
