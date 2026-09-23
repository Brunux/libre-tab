#!/usr/bin/env python3
"""Builds the Libre Tab logo in every version from one set of shapes.

The mark: a campfire flame shaped like a guitar pick, built from flat
faceted planes (the layered, geometric style of Flutter's own logo), with
three tab-staff "strings" cut through it, on two crossed logs. The sparks
flying off it are the chords everyone knows: G, C, D, Em, Am.

    python3 -m pip install fonttools   # once
    python3 branding/generate.py

Writes SVGs to branding/svg/, PNGs to branding/png/ and the app icon
sources to branding/app_icon/. PNGs are rendered with headless Chrome.
"""

import base64
import pathlib
import subprocess
import tempfile

from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.ttLib import TTFont

ROOT = pathlib.Path(__file__).resolve().parent
PROJECT = ROOT.parent
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Palettes, matching the app themes (docs/DESIGN.md).
FULL = dict(
    flame_light="#F7B548",  # lit side of the flame
    flame_dark="#E4702A",  # shadow side
    facet_light="#FFCB63",  # upper facet, lit side
    facet_dark="#CF5A1E",  # upper facet, shadow side
    core_light="#FFE39E",  # inner flame
    core_dark="#FFC45A",
    spark="#FFD37A",
    log_back="#6B3F22",
    log_front="#9A5E36",
    log_end="#C98A55",
    cut="#100D0A",  # the strings: cut out of the flame
)
RED_NIGHT = dict(
    flame_light="#FF6A5C",
    flame_dark="#C43A2F",
    facet_light="#FF8A7E",
    facet_dark="#A82F25",
    core_light="#FFC2B9",
    core_dark="#FF9A8C",
    spark="#FFA094",
    log_back="#3A0C0A",
    log_front="#5C1612",
    log_end="#8A2A22",
    cut="#000000",
)


# The sparks: common campfire chords rising off the flame, as outlines (so
# the SVGs need no font). Bigger and brighter near the fire, smaller and
# cooler as they fly up. (chord, centre x, centre y, cap height, degrees,
# opacity)
SPARKS = (
    ("G", 772, 262, 92, 12, 1.0),
    ("C", 268, 318, 76, -14, 0.95),
    ("D", 866, 420, 60, 16, 0.85),
    ("Em", 318, 142, 56, -10, 0.8),
    ("Am", 694, 92, 48, 9, 0.7),
)
SPARK_FONT = PROJECT / "assets/fonts/AtkinsonHyperlegible-Bold.ttf"


def chord_outline(text, cx, cy, cap, angle):
    """[text] as one SVG path d, centred on ([cx], [cy])."""
    font = TTFont(SPARK_FONT)
    glyphs = font.getGlyphSet()
    cmap = font.getBestCmap()
    upm = font["head"].unitsPerEm
    cap_units = font["OS/2"].sCapHeight or upm * 0.7
    k = cap / cap_units
    names = [cmap[ord(c)] for c in text]
    width = sum(glyphs[n].width for n in names)
    parts, pen_x = [], -width / 2
    for n in names:
        pen = SVGPathPen(glyphs)
        glyphs[n].draw(pen)
        parts.append(
            f'<path transform="translate({pen_x:.0f} 0)" d="{pen.getCommands()}"/>'
        )
        pen_x += glyphs[n].width
    return (
        f'<g transform="translate({cx} {cy}) rotate({angle}) '
        f'scale({k:.5f} {-k:.5f}) translate(0 {-cap_units / 2:.0f})">'
        f'{"".join(parts)}</g>'
    )


def sparks(color, faded=True):
    return "".join(
        f'<g fill="{color}"'
        + (f' opacity="{o}"' if faded and o < 1 else "")
        + f">{chord_outline(t, x, y, h, a)}</g>"
        for t, x, y, h, a, o in SPARKS
    )


def mono_mark(color):
    """The mark in one color, for stamps and embossing. The tab strings,
    the inner flame's outline and the gap above the logs are real holes, so
    it works on any background."""
    lines = "".join(
        f'<rect x="200" y="{y}" width="624" height="11" rx="5.5" fill="#000"/>'
        for y in (598, 640, 682)
    )
    return f"""
  <defs><mask id="mono" maskUnits="userSpaceOnUse" x="0" y="0" width="1024" height="1024">
    <g transform="rotate(-15 512 836)">
      <rect x="232" y="800" width="560" height="72" rx="36" fill="#fff"/>
      <circle cx="756" cy="836" r="26" fill="#000"/>
    </g>
    <g transform="rotate(15 512 836)">
      <rect x="232" y="800" width="560" height="72" rx="36" fill="#fff"
        stroke="#000" stroke-width="20"/>
      <circle cx="268" cy="836" r="26" fill="#000"/>
    </g>
    <polygon points="318,700 214,466 420,618" fill="#fff"/>
    <polygon points="706,700 812,488 604,618" fill="#fff"/>
    <path d="{PICK}" fill="#fff" stroke="#000" stroke-width="24"/>
    <path d="{PICK}" fill="#fff"/>
    <path d="{CORE}" fill="none" stroke="#000" stroke-width="14"/>
    <clipPath id="monopick"><path d="{PICK}"/></clipPath>
    <g clip-path="url(#monopick)">{lines}</g>
    {sparks("#fff", faded=False)}
  </mask></defs>
  <rect width="1024" height="1024" fill="{color}" mask="url(#mono)"/>
"""


DARK_BG = "#100D0A"
LIGHT_BG = "#FAF6EF"
# On light backgrounds the pale sparks disappear; burn them darker.
ON_LIGHT = dict(FULL, spark="#D0661F")

# ---------------------------------------------------------------- the mark
# Drawn on a 1024 × 1024 canvas.

PICK = (
    "M512 150 C600 252 778 420 770 566 C762 704 642 792 512 792 "
    "C382 792 262 704 254 566 C246 420 424 252 512 150 Z"
)
CORE = (
    "M512 420 C562 484 644 560 634 642 C626 712 572 748 512 748 "
    "C452 748 398 712 390 642 C380 560 462 484 512 420 Z"
)


def mark(p, cut_strings=True):
    """The mark's shapes, as SVG, for palette [p]."""
    strings = ""
    if cut_strings:
        # Three tab lines across the lower flame, cut out of it.
        strings = "".join(
            f'<rect x="200" y="{y}" width="624" height="11" rx="5.5" '
            f'fill="{p["cut"]}" clip-path="url(#pick)"/>'
            for y in (598, 640, 682)
        )
    return f"""
  <defs><clipPath id="pick"><path d="{PICK}"/></clipPath></defs>
  <!-- logs: back one darker, front one lighter, with cut ends -->
  <g transform="rotate(-15 512 836)">
    <rect x="232" y="800" width="560" height="72" rx="36" fill="{p["log_back"]}"/>
    <circle cx="756" cy="836" r="26" fill="{p["log_end"]}"/>
  </g>
  <g transform="rotate(15 512 836)">
    <rect x="232" y="800" width="560" height="72" rx="36" fill="{p["log_front"]}"/>
    <circle cx="268" cy="836" r="26" fill="{p["log_end"]}"/>
  </g>
  <!-- flame tongues either side: angled flat planes -->
  <polygon points="318,700 214,466 420,618" fill="{p["flame_dark"]}"/>
  <polygon points="706,700 812,488 604,618" fill="{p["flame_light"]}"/>
  <!-- the pick-shaped flame, lit side and shadow side -->
  <g clip-path="url(#pick)">
    <rect x="200" y="120" width="312" height="700" fill="{p["flame_light"]}"/>
    <rect x="512" y="120" width="312" height="700" fill="{p["flame_dark"]}"/>
    <!-- upper facets: a chevron fold from the tip, lighter on the lit side -->
    <polygon points="512,140 512,600 230,380" fill="{p["facet_light"]}"/>
    <polygon points="512,140 794,380 512,600" fill="{p["facet_dark"]}"/>
  </g>
  <!-- inner flame -->
  <clipPath id="core"><path d="{CORE}"/></clipPath>
  <g clip-path="url(#core)">
    <rect x="380" y="400" width="132" height="360" fill="{p["core_light"]}"/>
    <rect x="512" y="400" width="132" height="360" fill="{p["core_dark"]}"/>
  </g>
  {strings}
  <!-- sparks: chords flying off the fire -->
  {sparks(p["spark"])}
"""


def svg(width, height, body, view=None):
    view = view or f"0 0 {width} {height}"
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" '
        f'height="{height}" viewBox="{view}">{body}</svg>\n'
    )


def placed(p, size, x, y, cut_strings=True):
    """The mark scaled to [size] px with its canvas at ([x], [y])."""
    return (
        f'<g transform="translate({x} {y}) scale({size / 1024})">'
        f"{mark(p, cut_strings)}</g>"
    )


def glow(width, height, bg, color="#3A2410"):
    return (
        '<defs><radialGradient id="glow" cx="50%" cy="58%" r="55%">'
        f'<stop offset="0" stop-color="{color}"/>'
        f'<stop offset="1" stop-color="{bg}"/></radialGradient></defs>'
        f'<rect width="{width}" height="{height}" fill="{bg}"/>'
        f'<rect width="{width}" height="{height}" fill="url(#glow)"/>'
    )


# ------------------------------------------------------------- wordmark

FONT = PROJECT / "assets/fonts/Fraunces-Variable.ttf"
BODY_FONT = PROJECT / "assets/fonts/AtkinsonHyperlegible-Regular.ttf"


def font_face():
    """Fonts embedded so lockup SVGs look right anywhere (SIL OFL allows
    embedding)."""
    fraunces = base64.b64encode(FONT.read_bytes()).decode()
    body = base64.b64encode(BODY_FONT.read_bytes()).decode()
    return (
        "<style>"
        "@font-face{font-family:Fraunces;"
        f"src:url(data:font/ttf;base64,{fraunces})}}"
        "@font-face{font-family:Atkinson;"
        f"src:url(data:font/ttf;base64,{body})}}"
        ".word{font-family:Fraunces;font-weight:600;"
        "font-variation-settings:'wght' 600,'opsz' 144;letter-spacing:-0.01em}"
        ".tag{font-family:Atkinson;letter-spacing:0.02em}"
        "</style>"
    )


def wordmark(x, y, size, color, tagline=None, tag_color=None, anchor="start"):
    tag = ""
    if tagline:
        tag = (
            f'<text class="tag" x="{x}" y="{y + size * 0.62}" '
            f'font-size="{size * 0.3}" fill="{tag_color}" '
            f'text-anchor="{anchor}">{tagline}</text>'
        )
    return (
        f'<text class="word" x="{x}" y="{y}" font-size="{size}" '
        f'fill="{color}" text-anchor="{anchor}">Libre Tab</text>{tag}'
    )


TAGLINE = "Your campfire songbook &amp; tuner"
TAGLINE_ES = "Tu cancionero y afinador para la fogata"

# ---------------------------------------------------------------- outputs


def outputs():
    """(name, width, height, svg) for every version."""
    out = []

    # The mark alone.
    out += [
        ("mark", 1024, 1024, svg(1024, 1024, mark(FULL))),
        ("mark-red-night", 1024, 1024, svg(1024, 1024, mark(RED_NIGHT))),
        (
            "mark-mono-cream",
            1024,
            1024,
            svg(1024, 1024, mono_mark("#F4EDE3")),
        ),
        (
            "mark-mono-dark",
            1024,
            1024,
            svg(1024, 1024, mono_mark("#1E1812")),
        ),
    ]

    # App icon (iOS: full square, no transparency; the system rounds it).
    icon = glow(1024, 1024, DARK_BG) + placed(FULL, 1000, 12, 20)
    out.append(("app-icon", 1024, 1024, svg(1024, 1024, icon)))
    # Android adaptive icon foreground: the mark inside the 66 % safe zone.
    out.append(
        ("android-foreground", 1024, 1024, svg(1024, 1024, placed(FULL, 660, 172, 170)))
    )

    # Profile pictures (circle-safe: the mark stays well inside).
    for name, bg, g in [
        ("avatar-dark", DARK_BG, "#3A2410"),
        ("avatar-light", LIGHT_BG, "#FFE9C7"),
        ("avatar-red-night", "#000000", "#2A0605"),
    ]:
        palette = {"dark": FULL, "light": ON_LIGHT}.get(name[7:], RED_NIGHT)
        body = glow(1024, 1024, bg, g) + placed(palette, 900, 62, 50)
        out.append((name, 1024, 1024, svg(1024, 1024, body)))

    fonts = font_face()

    # Horizontal lockups (mark + wordmark), transparent.
    for name, palette, color, tag in [
        ("lockup-on-dark", FULL, "#F4EDE3", "#A99C8B"),
        ("lockup-on-light", ON_LIGHT, "#1E1812", "#6A5D4F"),
    ]:
        body = fonts + placed(palette, 400, 0, 0) + wordmark(
            420, 238, 150, color, TAGLINE, tag
        )
        out.append((name, 1640, 400, svg(1640, 400, body)))

    # Social: link preview (Open Graph / Facebook / LinkedIn), 1200 × 630.
    body = (
        fonts
        + glow(1200, 630, DARK_BG)
        + placed(FULL, 440, 70, 90)
        + wordmark(530, 300, 118, "#F4EDE3", TAGLINE, "#A99C8B")
        + '<text class="tag" x="534" y="420" font-size="30" fill="#F4A93A">'
        "Chords · Lyrics · Tuner · Offline</text>"
    )
    out.append(("social-og-1200x630", 1200, 630, svg(1200, 630, body)))

    # Social: X/Twitter header 1500 × 500 (sides get cropped on phones).
    body = (
        fonts
        + glow(1500, 500, DARK_BG)
        + placed(FULL, 380, 330, 60)
        + wordmark(720, 250, 110, "#F4EDE3", TAGLINE, "#A99C8B")
    )
    out.append(("social-header-1500x500", 1500, 500, svg(1500, 500, body)))

    # Social: square post (Instagram/Facebook), 1080 × 1080.
    body = (
        fonts
        + glow(1080, 1080, DARK_BG)
        + placed(FULL, 620, 230, 110)
        + wordmark(540, 850, 120, "#F4EDE3", TAGLINE, "#A99C8B", anchor="middle")
    )
    out.append(("social-post-1080", 1080, 1080, svg(1080, 1080, body)))

    # Social: story / reel cover, 1080 × 1920 (Spanish, as a second example).
    body = (
        fonts
        + glow(1080, 1920, DARK_BG)
        + placed(FULL, 760, 160, 420)
        + wordmark(540, 1330, 140, "#F4EDE3", TAGLINE_ES, "#A99C8B", anchor="middle")
    )
    out.append(("social-story-1080x1920", 1080, 1920, svg(1080, 1920, body)))

    return out


def render(svg_path, png_path, width, height, transparent):
    """Renders an SVG to PNG at its exact size with headless Chrome."""
    with tempfile.TemporaryDirectory() as tmp:
        html = pathlib.Path(tmp) / "page.html"
        html.write_text(
            "<!doctype html><html><body style='margin:0;background:transparent'>"
            f"<img src='{svg_path.as_uri()}' width='{width}' height='{height}' "
            "style='display:block'></body></html>"
        )
        args = [
            CHROME,
            "--headless=new",
            "--disable-gpu",
            "--hide-scrollbars",
            "--force-device-scale-factor=1",
            f"--window-size={width},{height}",
            f"--screenshot={png_path}",
        ]
        if transparent:
            args.append("--default-background-color=00000000")
        args.append(html.as_uri())
        subprocess.run(args, check=True, capture_output=True)


def main():
    svg_dir = ROOT / "svg"
    png_dir = ROOT / "png"
    icon_dir = ROOT / "app_icon"
    for d in (svg_dir, png_dir, icon_dir):
        d.mkdir(exist_ok=True)

    for name, width, height, content in outputs():
        svg_path = svg_dir / f"{name}.svg"
        svg_path.write_text(content)
        transparent = name.startswith(("mark", "lockup", "android-foreground"))
        target = icon_dir if name in ("app-icon", "android-foreground") else png_dir
        render(svg_path, target / f"{name}.png", width, height, transparent)
        print(f"{name}: {width}×{height}")


if __name__ == "__main__":
    main()
