import 'package:flutter/material.dart';
import 'package:libre_tab/app/theme/app_theme.dart';
import 'package:libre_tab/app/theme/libre_colors.dart';
import 'package:libre_tab/core/chordpro/song.dart';
import 'package:libre_tab/core/widgets/motion.dart';
import 'package:libre_tab/l10n/l10n.dart';

/// Draws a song with each chord above the syllable it belongs to
/// (docs/DESIGN.md § Song view). Lines wrap between words, never between a
/// chord and its syllable, so alignment survives any screen width.
class SongSheet extends StatelessWidget {
  const SongSheet({
    required this.song,
    this.fontSize = 22,
    this.chordLabel,
    this.onChordTap,
    super.key,
  });

  final Song song;

  /// Lyric size; chords are drawn at 85 % of it.
  final double fontSize;

  /// How to show a chord as written (e.g. transposed); as written if null.
  final String Function(String chord)? chordLabel;

  /// Called with the shown chord when it's tapped.
  final ValueChanged<String>? onChordTap;

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];
    SectionBlock? lastChorus;
    for (final block in song.blocks) {
      switch (block) {
        case SectionBlock():
          if (block.kind == SectionKind.chorus) lastChorus = block;
          sections.add(_Section(block: block, sheet: this));
        case ChorusRepeat(:final label):
          sections.add(
            lastChorus == null
                ? _SectionLabel(label ?? context.l10n.chorusLabel)
                : _Section(
                    block: lastChorus,
                    sheet: this,
                    labelOverride: label,
                  ),
          );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, section) in sections.indexed) ...[
          if (i > 0) SizedBox(height: fontSize * 1.1),
          section,
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.block,
    required this.sheet,
    this.labelOverride,
  });

  final SectionBlock block;
  final SongSheet sheet;
  final String? labelOverride;

  double get fontSize => sheet.fontSize;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label =
        labelOverride ??
        block.label ??
        switch (block.kind) {
          SectionKind.chorus => l10n.chorusLabel,
          SectionKind.bridge => l10n.bridgeLabel,
          _ => null,
        };

    final body = block.kind == SectionKind.tab
        ? _Tab(block: block, fontSize: fontSize)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in block.lines)
                switch (line) {
                  LyricLine() => _LyricLine(line: line, sheet: sheet),
                  CommentLine(:final text) => _Comment(text, fontSize),
                  EmptyLine() => SizedBox(height: fontSize * 0.6),
                  TabLine(:final text) => Text(text),
                },
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) _SectionLabel(label),
        if (block.kind == SectionKind.chorus)
          Container(
            padding: const EdgeInsets.only(left: 14),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: context.colors.line, width: 3),
              ),
            ),
            child: body,
          )
        else
          body,
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: context.colors.muted,
      ),
    ),
  );
}

class _Comment extends StatelessWidget {
  const _Comment(this.text, this.fontSize);

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: context.colors.surface2,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: fontSize * 0.75,
        fontStyle: FontStyle.italic,
        color: context.colors.text,
      ),
    ),
  );
}

/// Tab is shown exactly as written: monospace, no wrapping, scrolls sideways.
class _Tab extends StatelessWidget {
  const _Tab({required this.block, required this.fontSize});

  final SectionBlock block;
  final double fontSize;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Text(
      block.lines.map((l) => l is TabLine ? l.text : '').join('\n'),
      softWrap: false,
      style: TextStyle(
        fontFamily: AppFonts.mono,
        fontSize: fontSize * 0.7,
        height: 1.4,
        color: context.colors.text,
      ),
    ),
  );
}

/// One word (plus its trailing space), with the chord that starts on it.
typedef _Unit = ({String? chord, String text});

/// A chord name that rolls up to its new name when it changes (transpose,
/// capo), so it's clear what moved.
class _RollingChord extends StatelessWidget {
  const _RollingChord(this.label, {required this.style});

  final String label;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: context.flourish(const Duration(milliseconds: 220)),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    layoutBuilder: (current, previous) => Stack(
      alignment: Alignment.centerLeft,
      children: [...previous, ?current],
    ),
    transitionBuilder: (child, animation) {
      final incoming = child.key == ValueKey(label);
      return ClipRect(
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, incoming ? 0.8 : -0.8),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
      );
    },
    child: Text(label, key: ValueKey(label), style: style, softWrap: false),
  );
}

class _LyricLine extends StatelessWidget {
  const _LyricLine({required this.line, required this.sheet});

  final LyricLine line;
  final SongSheet sheet;

  double get fontSize => sheet.fontSize;

  static final _words = RegExp(r'\S*\s*');

  /// Splits segments into words so lines can wrap between them. A chord
  /// stays on the first word of its segment.
  List<_Unit> get _units => [
    for (final segment in line.segments)
      if (segment.lyric.isEmpty)
        (chord: segment.chord, text: '')
      else
        for (final (i, m) in _words.allMatches(segment.lyric).indexed)
          if (m.group(0)!.isNotEmpty)
            (chord: i == 0 ? segment.chord : null, text: m.group(0)!),
  ];

  /// Groups units that must stay together: a word split by a chord
  /// ("A-" + "mazing") never breaks across lines.
  static List<List<_Unit>> _groups(List<_Unit> units) {
    final groups = <List<_Unit>>[];
    var current = <_Unit>[];
    for (final unit in units) {
      current.add(unit);
      if (unit.text.isEmpty || unit.text.endsWith(' ')) {
        groups.add(current);
        current = [];
      }
    }
    if (current.isNotEmpty) groups.add(current);
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final chordStyle = TextStyle(
      fontSize: fontSize * 0.85,
      fontWeight: FontWeight.w700,
      height: 1.2,
      color: colors.chord,
    );
    final lyricStyle = TextStyle(
      fontSize: fontSize,
      height: 1.3,
      color: colors.text,
    );
    final hasChords = line.segments.any((s) => s.chord != null);
    final chordRow = fontSize * 0.85 * 1.25;

    Widget chord(String written) {
      final shown = sheet.chordLabel?.call(written) ?? written;
      final label = Padding(
        padding: EdgeInsets.only(right: fontSize * 0.3),
        child: _RollingChord(shown, style: chordStyle),
      );
      final onTap = sheet.onChordTap;
      if (onTap == null) return label;
      // Too small to be a good accessible button; screen-reader users get
      // every diagram from the song's "Chords" menu item instead.
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: () => onTap(shown),
        child: label,
      );
    }

    Widget unit(_Unit u) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasChords)
          SizedBox(
            height: chordRow,
            child: u.chord == null ? null : chord(u.chord!),
          ),
        // Non-breaking spaces keep the space width at the end of a word.
        Text(u.text.replaceAll(' ', ' '), style: lyricStyle, softWrap: false),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(bottom: fontSize * 0.35),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          for (final group in _groups(_units))
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [for (final u in group) unit(u)],
            ),
        ],
      ),
    );
  }
}
