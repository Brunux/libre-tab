<p align="center">
  <img src="branding/png/mark.png" alt="Libre Tab logo: a campfire with chords rising as sparks" width="160">
</p>

# Libre Tab

A songbook and guitar tuner for playing around the campfire. It works fully
offline: no account, no ads, no tracking.

<p align="center">
  <img src="docs/store/screenshots/1-songbook.png" alt="Songbook" width="200">
  <img src="docs/store/screenshots/2-song.png" alt="A song in campfire mode" width="200">
  <img src="docs/store/screenshots/3-red-night-capo.png" alt="Red night theme with a capo" width="200">
  <img src="docs/store/screenshots/5-setlist.png" alt="A setlist" width="200">
</p>

## Features

**Songbook**
- Chords above the lyrics, big enough to read at night.
- Hands-free auto-scroll: tap the lyrics to pause; the speed is remembered
  per song.
- Transpose, capo ("Sounds in A · Capo 2 · G shapes"), and a chord diagram
  for any chord you tap.
- Search by title, artist or a line of the lyrics (accents and apostrophes
  don't matter).
- Favorites and **setlists**: reorder by dragging, and swipe from one song to
  the next while playing.
- Swipe a song left for quick actions: add to a setlist, share, or delete
  (with Undo).
- Dark, **red night** and light themes. The screen stays on while a song is
  open.

**Adding songs**
- **Scan a song sheet** with the camera or from your photos. Text is read on
  the phone (Apple Vision on iPhone, Tesseract on Android) and each chord is
  placed over the syllable under it, even in proportional printed fonts.
- Paste chords-over-lyrics from anywhere; it's converted to ChordPro, with a
  live preview.
- Open `.cho`, `.chopro`, `.chordpro`, `.crd` or `.txt` files, including
  straight from Files, Mail, Safari or a chat app ("Open in Libre Tab" /
  "Share to").
- Seven public-domain campfire songs to start with (English and Spanish).

**Your data**
- Export the whole songbook as a `.zip` of `.cho` files, and import it on
  another phone. Importing the same backup twice adds nothing.
- Find duplicates: exact copies are merged, keeping their favorite star and
  setlist places; different versions are listed for you to compare.
- Delete all songs, with a clear confirmation, an "Export first" option and
  Undo.

**Tuner**
- Standard, half step down, Drop D, DADGAD, Open G and Open D.
- Auto-detects the string, or lock onto one string. A needle with a ±5 cent
  "in tune" zone, and a haptic tap when a string is in tune.
- Reference pitch from 432 to 446 Hz.
- Only listens while the tuner is on screen; nothing is recorded.

Songs are stored in the open [ChordPro](https://www.chordpro.org/) format, so
your songbook is never locked into this app. The app is in English and
Spanish.

## Status

All seven milestones are done: screen design, scaffold, music core, songbook,
campfire mode, tuner, polish (setlists, starter songs, export/import, app icon
and brand, store listing), and camera import. It runs on iPhone; the Android
build compiles but hasn't been tried on a device yet. 460+ tests pass.

See the [roadmap](docs/TECH_STACK.md#10-milestones).

## Platforms

iOS 14+ and Android 7.0+ (API 24).

## Development

Requirements: Flutter 3.44+ (Dart 3.12+), Xcode for iOS, Android SDK for
Android.

```bash
flutter pub get
flutter run --release   # on a device (debug builds need the VM service)
flutter test
flutter analyze
dart run build_runner build --delete-conflicting-outputs   # after Drift schema changes
```

Brand and app icon: see [branding/README.md](branding/README.md) (runs
`branding/generate.py`, then `dart run flutter_launcher_icons`).

## Documentation

| Doc | What's in it |
|---|---|
| [docs/TECH_STACK.md](docs/TECH_STACK.md) | Stack, packages, architecture, tuner pipeline, testing, milestones |
| [docs/SONG_FORMAT.md](docs/SONG_FORMAT.md) | The ChordPro subset Libre Tab reads and writes, imports, file types, export/import |
| [docs/DESIGN.md](docs/DESIGN.md) | Navigation, themes, fonts, and every screen: songbook, song view, editor, tuner, setlists, settings |
| [docs/store/listing.md](docs/store/listing.md) | App Store / Google Play text (EN + ES), privacy answers, screenshots |
| [PRIVACY.md](PRIVACY.md) | Privacy statement: no data collected |
| [SECURITY.md](SECURITY.md) | Reporting vulnerabilities, security model, audit results |
| [branding/README.md](branding/README.md) | Logo, app icon, social media versions, colors, taglines |

## Project layout

```
lib/
  app/         router, theme, settings, localization setup
  core/        database (Drift + FTS5), ChordPro, music theory (pure Dart),
               pitch detection, files, shared widgets
  features/    library (songbook, setlists, import/export, duplicates),
               song_view, editor, tuner, settings
  l10n/        English and Spanish strings
assets/        fonts, starter songs
branding/      logo generator and outputs
docs/          design docs, store listing, screenshots
test/          mirrors lib/
```

## License

Copyright (C) 2026 Bruno Fosados

Libre Tab is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version. See [LICENSE](LICENSE) for the full text.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

The fonts (Atkinson Hyperlegible, Fraunces, JetBrains Mono) are under the SIL
Open Font License; the starter songs are in the public domain.
