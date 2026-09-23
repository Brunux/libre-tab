/// Pitch classes (C = 0 … B = 11) and how to spell them.
abstract final class Note {
  static const _sharps = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', //
  ];
  static const _flats = [
    'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B', //
  ];
  static const _naturals = {
    'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11, //
  };

  /// Pitch class of a note name like `F#`, `Bb`, `E♭`; null if not a note.
  static int? pitchClass(String name) {
    if (name.isEmpty || name.length > 2) return null;
    final natural = _naturals[name[0]];
    if (natural == null) return null;
    if (name.length == 1) return natural;
    return switch (name[1]) {
      '#' || '♯' => (natural + 1) % 12,
      'b' || '♭' => (natural + 11) % 12,
      _ => null,
    };
  }

  /// Name for a pitch class, e.g. `spell(10, flats: true)` → `Bb`.
  static String spell(int pitchClass, {required bool flats}) =>
      (flats ? _flats : _sharps)[pitchClass % 12];
}
