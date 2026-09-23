# Libre Tab

A campfire companion for acoustic guitar players.

- **Songbook** — keep your songs (lyrics with chords above them) on your phone,
  fully offline. Read them hands-free with auto-scroll, transpose, capo and chord
  diagrams, in a dark or red night theme that works next to the fire.
- **Tuner** — tune your acoustic guitar with the phone's microphone. Standard and
  common alternate tunings.

Songs are stored in the open [ChordPro](https://www.chordpro.org/) format, so
your songbook is never locked into this app.

> Status: early development. See the [roadmap](docs/TECH_STACK.md#10-milestones).

## Platforms

iOS and Android.

## Development

Requirements: Flutter 3.44+ (Dart 3.12+), Xcode for iOS, Android SDK for Android.

```bash
flutter pub get
flutter run          # on a connected device or simulator
flutter test
flutter analyze
```

## Documentation

| Doc | What's in it |
|---|---|
| [docs/TECH_STACK.md](docs/TECH_STACK.md) | Stack, packages, architecture, tuner pipeline, testing, milestones |
| [docs/SONG_FORMAT.md](docs/SONG_FORMAT.md) | The ChordPro subset Libre Tab reads and writes, and how imports are converted |

## Project layout

```
lib/
  app/         router, theme, localization
  core/        database, music theory (pure Dart), shared widgets
  features/    library, song_view, editor, tuner, settings
docs/          design docs
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
