# Libre Tab — Tech Stack

A campfire companion for acoustic guitar players: keep a personal songbook of
chords + lyrics offline, read it hands-free while playing, and tune the guitar
with the phone's microphone.

## 1. Product constraints that drive the stack

| Constraint | Consequence |
|---|---|
| Used outdoors, often with no signal | **100% offline.** No backend, no account. All data on device. |
| Hands are on the guitar | Auto-scroll, large text, screen never sleeps, one-tap controls. |
| Used at night by a fire | True-black dark theme + optional red "night vision" theme. |
| Campfire songs = lyrics with chords | Canonical format is **ChordPro**, not full tablature. ASCII tab blocks are supported for riffs/intros. |
| Tuner needs real-time audio | Mic PCM stream + pitch detection off the UI thread. |

## 2. Toolchain

- **Flutter 3.44 (stable) / Dart 3.12** — installed locally.
- **Targets:** iOS and Android phones (tablets supported by responsive layout). Desktop/web are out of scope for v1 (tuner mic APIs differ).
- **Xcode 26.5** + Android SDK — installed.

## 3. Packages

| Concern | Choice | Why |
|---|---|---|
| State management | `flutter_riverpod` | Testable, no `BuildContext` coupling, good fit for streams (DB queries, audio). |
| Navigation | `go_router` | Declarative routes, deep links later for song sharing. |
| Local database | `drift` + `sqlite3_flutter_libs` | Real SQL, typed queries, migrations, reactive `watch()` streams, **FTS5 full-text search** across title/artist/lyrics. |
| Code generation | `build_runner`, `drift_dev` | Only for Drift. Models use Dart 3 `sealed` classes / records — no `freezed`. |
| Settings | `shared_preferences` | Theme, font size, default scroll speed, reference pitch (A4). |
| Keep screen on | `wakelock_plus` | Enabled only on the song view and tuner. |
| Import / export | `file_picker`, `share_plus` | Import `.cho`/`.chopro`/`.txt`; export single song or whole songbook. |
| Mic audio stream | `record` | Streams raw PCM16 on iOS/Android. |
| Mic permission | `permission_handler` | Explicit rationale screen before the OS prompt. |
| Localization | `flutter_localizations` + `intl` (ARB files) | Spanish + English from day one. |
| Lints | `very_good_analysis` | Strict, catches issues early. |
| Tests | `flutter_test`, `mocktail` | Unit, widget and golden tests. |

Written in-house (no package) on purpose — small, core to the app, and easy to test:

- **ChordPro parser + renderer**
- **Chord-over-lyrics importer** (converts the common "chords on the line above" text into ChordPro)
- **Transposer** (sharps/flats aware, capo aware)
- **Chord diagram painter** (`CustomPainter` + a bundled JSON of open-position voicings)
- **Pitch detector** (McLeod Pitch Method)

## 4. Song format decision

**Store ChordPro, display chords-over-lyrics, import chords-over-lyrics.**
Accepted 2026-09-22. Full format spec: [SONG_FORMAT.md](SONG_FORMAT.md).

| Option | Open? | Simple? | Survives transpose / wrap? | Fits camera import? | Verdict |
|---|---|---|---|---|---|
| Plain "chords over lyrics" text | Yes (no spec) | Very | No: alignment breaks when `C` becomes `C#m` or a line wraps | Directly what's on paper | **Import + display** |
| **ChordPro** (chordpro.org) | Yes: open, free spec; open-source reference implementation | Yes: plain text + `[C]` | Yes: each chord is attached to a syllable | OCR output converts to it | **Storage (source of truth)** |
| OpenLyrics (XML, OpenLP) | Yes | No: verbose XML | Yes | Poor | Rejected |
| MusicXML / Guitar Pro / alphaTex | Mixed | No | Yes | No | Overkill for campfire songs |

Same song, two representations:

```
Chords over lyrics (what users see and photograph)
   G         G7       C          G
A-mazing grace, how sweet the sound

ChordPro (what we store)
A-[G]mazing [G7]grace, how [C]sweet the [G]sound
```

### Import pipeline (shared by paste, file and camera)

```
source ─▶ lines with horizontal positions ─▶ classify line: chord / lyric / directive / tab
       ─▶ pair each chord line with the lyric line below
       ─▶ insert [Chord] at the lyric character under the chord's x position
       ─▶ ChordPro text ─▶ editor preview ─▶ user confirms ─▶ save
```

- **Paste / .txt file:** x position = character column (monospace text).
- **Camera (future):** on-device OCR returns a bounding box for every word, so
  alignment uses real pixel x-coordinates. That works even with the proportional
  fonts in printed songbooks, where counting characters would fail.
- **.cho / .chopro file:** already ChordPro, parsed directly.
- A chord line is one where every token matches the chord grammar
  (`[A-G][#b]?(m|maj|min|dim|aug|sus)?\d*(/[A-G][#b]?)?`, plus `N.C.`, `x2`, `|`).
- **OCR engine options for later:** Google ML Kit Text Recognition
  (`google_mlkit_text_recognition`): best accuracy, on-device and free, but
  closed-source binaries. Tesseract (Apache-2.0): fully open source, weaker on
  phone photos. Choose when the camera milestone starts.

## 5. Feature 1 — Songbook (store + display)

### Data model (Drift / SQLite)

```
songs         id, title, artist, key, capo, tempo_bpm, body_chordpro,
              created_at, updated_at, favorite, scroll_speed
setlists      id, name, created_at            -- "Friday campfire"
setlist_songs setlist_id, song_id, position
songs_fts     FTS5 virtual table over title, artist, body (lyrics without chords)
```

The song body is stored as **ChordPro text** — it's the source of truth,
human-readable, and trivially exportable. Parsing happens on open; it's fast
for song-sized text.

### Rendering pipeline

```
ChordPro text ──parse──▶ Song AST (sections → lines → [chord?, lyric] segments)
              ──transpose(n, capo)──▶ Song AST
              ──layout(fontSize, width)──▶ widgets (chord row above lyric row,
                                           wraps lines without splitting chord/word pairs)
```

Supported ChordPro subset for v1: `{title}`, `{artist}`, `{key}`, `{capo}`,
`{comment}`, `{start_of_chorus}`/`{soc}`, `{start_of_verse}`,
`{start_of_tab}`/`{sot}` (rendered monospaced, no wrapping), inline `[C]` chords.

### Song view (the "campfire mode")

- Auto-scroll with adjustable speed, tap anywhere to pause/resume; speed saved per song.
- Pinch-to-zoom font size; long lines wrap instead of scrolling sideways.
- Transpose ± semitones and capo shown in a bottom bar; tapping a chord shows its diagram.
- Screen kept awake; dark and red night themes.
- Swipe left/right to move through a setlist.

## 6. Feature 2 — Tuner

### Audio pipeline

```
Mic (record, PCM16 mono, 44.1 kHz)
  └▶ ring buffer, 4096-sample windows, 50% overlap (~46 ms updates)
      └▶ background isolate:
           noise gate (RMS threshold)
           └▶ McLeod Pitch Method (normalized square difference + parabolic interpolation)
               └▶ frequency Hz + clarity (confidence)
  └▶ UI isolate: median smoothing → nearest string/note → cents offset → needle
```

- **Why MPM:** accurate on guitar's low E (82.41 Hz) with a 4096-sample window,
  robust to the strong 2nd harmonic of acoustic strings (fewer octave errors than
  plain autocorrelation), and cheap enough to run in pure Dart.
- **Why an isolate:** keeps the needle animation at 60 fps.
- **Modes:** auto-detect string, or lock to one string.
- **Tunings:** Standard (EADGBE), Half-step down, Drop D, DADGAD, Open G, Open D; configurable A4 reference (432–446 Hz, default 440).
- **"In tune" rule:** within ±5 cents for ~300 ms → green state + light haptic.

### Platform setup

- iOS: `NSMicrophoneUsageDescription` in `Info.plist`.
- Android: `RECORD_AUDIO` permission in `AndroidManifest.xml`.

## 7. Project structure (feature-first)

```
lib/
  main.dart
  app/                 router, theme (dark / red night), l10n setup
  core/
    database/          Drift schema, DAOs, migrations
    music/             Note, Chord, transposer, tunings   ← pure Dart, no Flutter
    widgets/           shared UI bits
  features/
    library/           song list, search, setlists, import/export
    song_view/         ChordPro parser, renderer, auto-scroll, chord diagrams
    editor/            create/edit song (ChordPro text + live preview)
    tuner/             audio capture, pitch detector isolate, tuner UI
    settings/
assets/
  chords/voicings.json
  songs/               a few public-domain starter songs
test/                  mirrors lib/
```

Every feature follows: `data/` (repositories) → `application/` (Riverpod
providers) → `presentation/` (widgets). `core/music` has zero Flutter imports
so it's fast to unit test.

## 8. Testing strategy

| Layer | How |
|---|---|
| ChordPro parser, importer, transposer | Table-driven unit tests with fixture files; importer round-trip (chords-over-lyrics → ChordPro → rendered) must match. |
| Pitch detector | Feed synthetic sine + harmonics for every string frequency (with noise) and assert error < 1 cent; add recorded real-guitar WAV fixtures. |
| Database | Drift in-memory database. |
| Song view | Golden tests for chord/lyric layout at several widths and font sizes. |
| Tuner UI | Widget tests with a fake pitch stream. |

## 9. Out of scope for v1 (possible later)

- Cloud sync / sharing between friends (could add later via export files or a sync backend).
- Scraping third-party tab sites (licensing issues). Users import their own files.
- Full Guitar Pro / MusicXML tablature notation.
- Metronome, chord recognition from audio.

## 10. Milestones

0. **Screen design** — clickable mockups of songbook, song view, add song and tuner, in dark / red night / light themes. Final choices recorded here before milestone 1.
1. **Scaffold** — `flutter create`, lints, theme, router, l10n, tests running.
2. **Music core** — Note/Chord model, ChordPro parser, transposer (+ tests).
3. **Songbook** — Drift schema, library list, search, editor, import/export.
4. **Campfire mode** — song view, auto-scroll, transpose/capo, chord diagrams, wakelock.
5. **Tuner** — mic permission, audio stream, MPM isolate, tuner UI, alternate tunings.
6. **Polish** — setlists, starter songs, app icon, store assets.
7. **Camera import** — photo → OCR with word boxes → same chords-over-lyrics importer → ChordPro.
