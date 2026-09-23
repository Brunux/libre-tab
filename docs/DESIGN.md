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
| `muted` | `#A99C8B` | `#DA4C40` | `#6A5D4F` |
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

Swiping a song row left reveals quick actions: **Setlist** (the Add to setlist
sheet), **Share** (the `.cho` file) and **Delete** (red). Only one row is open
at a time. Delete happens at once with an **Undo** snackbar (8 s) that puts the
song back with its id, favorite and setlist places; that's quicker than a
dialog and just as safe. Screen readers get the same three as custom actions
on the row. (`flutter_slidable`)

### 2. Song view (campfire mode)
Header: back, title, "artist · Key G" (with capo: "Sounds in A · Capo 2 · play G
shapes"), favorite star, theme switch, ⋮ menu (Chords, Edit song, Share,
Delete — delete asks first). "Chords" shows diagrams for every chord in the song;
it's also how screen-reader users reach diagrams, since chords in the lyrics are
too small to be good accessible buttons. Body: sections with small uppercase labels; each lyric
line is a wrapping row of chord/lyric pairs, chord above its syllable. Tapping a
chord opens a bottom sheet with its diagram. Diagrams show fret numbers down
the left and, under each string, the fret to press (C: × 3 2 0 1 0), so shapes
are easy to learn; screen readers hear the same, string by string. Bottom dock:
- Row 1: Key − / + (transpose), Capo − / +
- Row 2: A− / A+ (text size), Speed − / ▶ Speed N / +

Screen stays awake; auto-scroll stops at the end.

Details (milestone 4):
- Tap anywhere on the lyrics to pause/resume auto-scroll. While a finger is
  on the lyrics auto-scroll holds still; scrolling by hand moves the song and
  auto-scroll carries on from there once the scroll settles (no second tap).
  Scrolling while paused stays paused.
- The song has room above and below it, half the visible height (no more),
  so it can scroll past its ends: auto-scroll brings the last lines up to the
  middle of the screen instead of stopping with them at the bottom edge. It
  opens scrolled past the top room, so the first line is at the top; Play at
  the end starts again from there.
  Play at the end of the song starts again from the top.
- Speeds 1–6 (6–45 px/s at 22 px text, scaled with text size); the last speed
  is remembered per song.
- The song opens at its own `{capo}`, showing chords as written. Transpose
  range ±11 semitones, capo 0–11.
- Text size (16–36, step 2) and the theme are remembered between launches.

### 3. Add / edit song
One screen for both. Header: cancel (asks "Discard changes?" if anything
changed), "Add song" / "Edit song", Save (enabled once there is a title and
text). Fields: Title, Artist. Buttons: **Open file** and **Scan photo** —
simpler than the Paste / File / Camera tabs in the mockup, since the text box
is always there to paste into. Text box (monospace) takes chords-over-lyrics
or ChordPro; `{title}`/`{artist}` lines pasted in fill the fields. Result with
Preview / ChordPro toggle and a summary ("Chord lines placed: 4 · Sections
found: 2", or "Already in ChordPro format."). Nothing is saved until Save.
**Scan photo** (milestone 7) asks "Take a photo" or "Choose from photos"
(the system picker: no permission, only the photos chosen are shared; up to
10, read in the order picked, "Reading photo 2 of 3…"). It then fills
Title/Artist (if empty) from the first page and puts each page's
chords-over-lyrics in the text box, one below the other, and says "Check the
chords against the photo before saving." Another scan is added below too.
Refused camera, no text found and unreadable photos each get a plain message.
Add song also has **Start over** (disabled while empty), which empties title,
artist and text to begin another song, with Undo.
A song file opened from another app ("Open in Libre Tab", "Share to") lands
here the same way, already filled in (docs/SONG_FORMAT.md § Files).

### Empty and error states
- Empty songbook: "Your songbook is empty. Add your first song."
- Search with no results: "No songs match your search."
- Favorites with none: "No favorites yet. Tap the star on a song to add it."
- Unknown or deleted song: "This song isn't in your songbook."

### 4. Tuner
Header with A4 reference · tuning picker · big note + octave + live Hz · needle
gauge (−50…+50 cents, green zone ±5) · status ("Too low · tighten" / "Too high ·
loosen" / "In tune") · Auto-detect toggle · six string buttons (6th → 1st);
tapping one locks to that string (tap again, or Auto-detect, to unlock).
In-tune string button turns `good`, with one haptic tap. First visit shows
"Tune your guitar" and a Start button before the OS microphone prompt; if the
microphone is refused, the screen says where to allow it. Tapping "A4 = 440 Hz"
opens a slider (432–446 Hz) with "Back to 440". The tuner only listens while
its tab is on screen and the app is in front, and keeps the screen on.

### 5. Setlists (milestone 6)
- **Songbook, "Setlists" chip:** the list shows setlists instead of songs
  (name, "7 songs"); search filters them by name. The floating button becomes
  "New setlist", which asks for a name and opens the new setlist.
- **Setlist screen:** header with back, name and ⋮ (Rename, Delete — delete
  asks first; songs stay in the songbook). A "Play" button opens the first
  song. Rows: position, title, artist · key, a drag handle to reorder and a
  remove button. "Add songs" opens a sheet with every song and a checkbox;
  songs already in the setlist are ticked, Done saves. Tapping a row plays
  from that song.
- **Playing a setlist:** the song view, and swiping left/right moves to the
  next/previous song. The subtitle starts with the position ("2/7 · …").
  Screen readers get the same through the page's scroll actions.
- **Song view ⋮ → Add to setlist:** a sheet listing setlists with a checkbox
  each, plus "New setlist".
- Empty setlists list: "No setlists yet. Make one for your next campfire."
  Empty setlist: "No songs in this setlist yet."

### 6. Settings (milestone 6)
Theme (Dark / Red night / Light) · **Songbook**: Export all songs (a `.zip` of
`.cho` files through the share sheet), Import songs (`.zip` or a single song
file; adds every song, skips files that aren't songs), Add starter songs
(adds the public-domain starters that aren't in the songbook) · **About**:
version, GPL-3.0 note and the licenses page. · **Danger zone** (last, in the
error color): Delete all songs.

**Find duplicates** (Songbook section, needs 2+ songs) groups songs whose title
and artist match once case, accents, spacing and punctuation are ignored, then
compares their text with line endings, trailing spaces, runs of blank lines
and directive spelling (`{Title:`, `{t:`) ignored. Comparing the normalised
text directly is simpler than a checksum and just as exact for a songbook's
size.
- **Exact copies**: listed, then one "Remove N copies" button. The copy kept
  is the favorite, else the one in more setlists, else the oldest; it takes
  the others' favorite star and setlist places, so nothing is lost. Undo
  restores everything as it was.
- **Same title, different text**: possibly different arrangements, so never
  removed automatically. Each version is listed (first lyric line, key, date
  added) and opens in the song view to compare and delete by hand.

Delete all songs follows the usual rules for destructive actions: it's
disabled when the songbook is empty; the dialog says exactly what's lost
("Delete all 12 songs?", setlists are left empty), offers **Export first**,
keeps Cancel as the safe choice and makes the destructive button red; and
after deleting, an **Undo** snackbar can still bring everything back. Undo
lives in memory only, so it's gone if the app is closed.

Starter songs are added automatically on the very first launch only; after
that the songbook is the user's (deleting them is fine, they don't come back
unless asked). The empty songbook also offers "Add starter songs".
