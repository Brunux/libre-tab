# Song format

Libre Tab stores every song as **ChordPro** text. It shows songs the way players
expect, with chords above the lyrics, and imports that same layout from pasted
text, `.txt` files and (later) photos.

- Spec: <https://www.chordpro.org/chordpro/>. Open, free format.
- Why ChordPro: see [TECH_STACK.md § 4](TECH_STACK.md#4-song-format-decision).
- Decision accepted: 2026-09-22.

## Example

```chordpro
{title: Amazing Grace}
{artist: John Newton}
{key: G}
{capo: 0}

{start_of_verse}
A-[G]mazing [G7]grace, how [C]sweet the [G]sound
That [G]saved a wretch like [D]me
{end_of_verse}
```

Displayed as:

```
   G         G7       C          G
A-mazing grace, how sweet the sound
     G                   D
That saved a wretch like me
```

## Supported subset (v1)

Anything outside this list is kept in the stored text untouched (so round-trips
are lossless) but is ignored when rendering.

### Metadata directives

| Directive | Short form | Meaning |
|---|---|---|
| `{title: …}` | `{t: …}` | Song title (required; import asks for one if missing) |
| `{artist: …}` | `{a: …}` | Artist |
| `{key: …}` | | Original key, e.g. `G`, `Am` |
| `{capo: n}` | | Suggested capo fret |
| `{tempo: n}` | | BPM, used as the default auto-scroll hint |

### Section directives

| Directive | Short form | Rendering |
|---|---|---|
| `{start_of_verse}` … `{end_of_verse}` | `{sov}` … `{eov}` | Normal block |
| `{start_of_chorus}` … `{end_of_chorus}` | `{soc}` … `{eoc}` | Indented with a side bar |
| `{chorus}` | | Repeats the last chorus |
| `{start_of_tab}` … `{end_of_tab}` | `{sot}` … `{eot}` | Monospace, no wrapping, horizontal scroll |
| `{comment: …}` | `{c: …}` | Highlighted note, e.g. "Intro x2" |

A section directive may carry a label: `{start_of_verse: Verse 2}`.

### Chords

- Written inline in square brackets, just before the syllable where they're played:
  `A-[G]mazing`.
- A chord with no lyric after it (e.g. at the end of a line or an instrumental
  bar) is rendered as a chord on its own: `[G] [C] [D]`.
- Chord grammar the app understands (for transpose and diagrams):

  ```
  root     = A–G, optional # or b
  quality  = m | min | maj | dim | aug | sus2 | sus4 | add  (optional)
  ext      = 6 | 7 | 9 | 11 | 13 (optional, may follow quality, e.g. maj7, m7, add9)
  bass     = "/" root (optional slash chord, e.g. D/F#)
  ```

  Anything that doesn't match (e.g. `[N.C.]`, `[x2]`) is shown as-is and never
  transposed.

### Comments and blank lines

- Lines starting with `#` are ChordPro comments: stored, not shown.
- Blank lines separate stanzas.

## Transposing

Transposing changes only how the song is shown. The stored text keeps the
original chords unless the user explicitly chooses "Save in this key".

- Sharps vs flats follow the target key (e.g. transposing to F uses `Bb`, to E uses `F#`).
- Capo: with capo on fret *n*, shown chord shapes are shifted down *n* semitones
  so the player reads the shapes they actually finger.

## Importing chords-over-lyrics

Input like this (pasted text or a `.txt` file):

```
   G         G7       C          G
A-mazing grace, how sweet the sound
```

is converted to ChordPro:

1. **Classify each line.** A line is a *chord line* if every whitespace-separated
   token matches the chord grammar (or is `|`, `N.C.`, `xN`). Lines like
   `[Chorus]`, `Verse 1:` or `Intro:` become section directives or comments.
   Runs of six lines made mostly of `-`, digits and `|` become a
   `{start_of_tab}` block.
2. **Pair lines.** A chord line followed by a lyric line is merged. A chord line
   followed by a blank line, another chord line or the end of the song stays a
   chords-only line.
3. **Align.** Each chord is inserted into the lyric at the character under the
   chord's starting column. If the chord is past the end of the lyric, the lyric
   is padded with spaces.
4. **Review.** The result opens in the editor with a live preview; nothing is
   saved until the user confirms.

For the future camera import, step 3 uses each word's x position (in pixels)
from text recognition instead of character columns. Steps 1, 2 and 4 are the same.

## Files

| Extension | Handling |
|---|---|
| `.cho`, `.chopro`, `.chordpro`, `.crd` | Parsed as ChordPro |
| `.txt` | Treated as ChordPro if it contains `{…}` directives or `[Chord]` markup; otherwise run through the chords-over-lyrics importer |

Export writes one `.cho` per song, or a `.zip` of them for the whole songbook.
Text encoding is always UTF-8.
