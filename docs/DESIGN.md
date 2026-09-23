# UI design

Approved 2026-09-22 (milestone 0). Clickable mockups:
<https://claude.ai/artifact/85osB4oLaGtUpNBLFHPx5k>

## Navigation

```
Bottom tabs:  [ Songbook ]  [ Tuner ]

Songbook ──tap song──▶ Song view ──back──▶ Songbook
    │  └─settings icon─▶ Settings
    └──"Add song"──▶ Add song ──Save──▶ Song view
                          └──Cancel──▶ Songbook
```

- Two bottom tabs only. Settings open from the icon in the Songbook header.
- Song view and Add song are full-screen routes on top of the tabs (no bottom bar).

## Themes

Three themes, same token names. Song view has a one-tap theme switch (moon
icon) that cycles Dark → Red night → Light; the default comes from Settings.

| Token | Dark (default) | Red night | Light |
|---|---|---|---|
| `bg` | `#100D0A` | `#000000` | `#FAF6EF` |
| `surface` | `#1B1712` | `#120303` | `#FFFFFF` |
| `surface2` | `#282119` | `#1E0606` | `#F1EADF` |
| `line` | `#3A3027` | `#3A0C0A` | `#E3D8C8` |
| `text` | `#F4EDE3` | `#FF6A5C` | `#1E1812` |
| `muted` | `#A99C8B` | `#D2473B` | `#6A5D4F` |
| `chord` | `#F4A93A` | `#FFA094` | `#A94C06` |
| `accent` | `#F4A93A` | `#FF5A4B` | `#B8480A` |
| `onAccent` | `#1A1107` | `#000000` | `#FFFFFF` |
| `good` (in tune) | `#7BD389` | `#FFC2B9` | `#1F7A3B` |

Red night uses only red hues so it doesn't ruin night vision; "in tune" there is
shown by brightness, not green.

## Typography

| Use | Font | Notes |
|---|---|---|
| Lyrics, UI | Atkinson Hyperlegible 400/700 | Built for legibility; lyrics default 22 px, adjustable 16–36 |
| Titles, big note name, chord name in diagram | Fraunces 600 | Screen titles 34 px, song title 24 px, tuner note 104 px |
| Paste box, ChordPro source | JetBrains Mono 400 | Monospace keeps chords-over-lyrics alignment |

Chords: 700 weight, `chord` color, 0.85 × lyric size. Fonts are bundled in the
app (all SIL Open Font License), no network fetch.

## Sizing

- Touch targets ≥ 44 px; steppers and song rows 48–52 px.
- Corner radius: 12–14 px controls, 24 px bottom sheets.
- Screen padding 16–20 px.

## Screens

### 1. Songbook
Header (title + settings icon) · search field · chips: All songs / Favorites /
Setlists · song rows (key badge, title, artist · capo, favorite star) ·
floating "Add song" button · bottom tabs.

### 2. Song view (campfire mode)
Header: back, title, "artist · Key G" (with capo: "Sounds in A · Capo 2 · play G
shapes"), theme switch. Body: sections with small uppercase labels; each lyric
line is a wrapping row of chord/lyric pairs, chord above its syllable. Tapping a
chord opens a bottom sheet with its diagram. Bottom dock:
- Row 1: Key − / + (transpose), Capo − / +
- Row 2: A− / A+ (text size), Speed − / ▶ Speed N / +

Screen stays awake; auto-scroll stops at the end.

### 3. Add song
Header: cancel, title, Save. Source switch: Paste / File / Camera (later). Title
and artist fields. Paste box (monospace). Result with Preview / ChordPro toggle
and a summary ("4 chord lines placed over the lyrics · 2 sections found").
Nothing is saved until Save.

### 4. Tuner
Header with A4 reference · tuning picker · big note + octave + live Hz · needle
gauge (−50…+50 cents, green zone ±5) · status ("Too low · tighten" / "Too high ·
loosen" / "In tune") · Auto-detect toggle · six string buttons (6th → 1st);
tapping one locks to that string. In-tune string button turns `good`.

## Not designed yet

Settings, setlist detail/editing, song editor (edit existing ChordPro), empty
songbook first-run state. Design these when their milestone starts.
