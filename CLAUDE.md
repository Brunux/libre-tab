# Libre Tab

Flutter app (iOS + Android): offline campfire songbook + acoustic guitar tuner.

- Design and decisions: `docs/TECH_STACK.md`. Song format spec: `docs/SONG_FORMAT.md`.
  Follow them; update the docs in the same change when a decision changes.
- Songs are stored as ChordPro text (source of truth). Display is chords above lyrics.
- Fully offline: no network calls, no backend, no analytics.
- Structure: feature-first under `lib/features/<feature>/{data,application,presentation}`.
  `lib/core/music` must stay pure Dart (no Flutter imports).
- State: Riverpod. Routing: go_router. DB: Drift. UI strings go through l10n (ES + EN).
- Parser, importer, transposer and pitch detector are written in-house and need
  unit tests.
- License: GPL-3.0-or-later. Only add dependencies with GPL-3.0-compatible
  licenses (MIT, BSD, Apache-2.0, LGPL, GPL-3.0 are fine; GPL-2.0-only is not).

## Commands

```bash
flutter pub get
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs   # after Drift schema changes
```
