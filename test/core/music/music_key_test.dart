import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/core/music/chord.dart';
import 'package:libre_tab/core/music/music_key.dart';

void main() {
  group('MusicKey.tryParse', () {
    test('major and minor keys', () {
      expect(MusicKey.tryParse('G'), const MusicKey(7));
      expect(MusicKey.tryParse('Am'), const MusicKey(9, minor: true));
      expect(MusicKey.tryParse('F#m'), const MusicKey(6, minor: true));
      expect(MusicKey.tryParse('Bb'), const MusicKey(10));
      expect(MusicKey.tryParse('E♭'), const MusicKey(3));
      expect(MusicKey.tryParse('Ebmin')?.name, 'Ebm');
    });

    for (final bad in ['', 'H', 'Am7', 'D/F#', 'Gsus4', 'Cmaj']) {
      test('"$bad" is not a key', () => expect(MusicKey.tryParse(bad), isNull));
    }
  });

  test('names use the conventional spelling', () {
    expect(const MusicKey(1).name, 'Db');
    expect(const MusicKey(6).name, 'F#');
    expect(const MusicKey(1, minor: true).name, 'C#m');
    expect(const MusicKey(3, minor: true).name, 'Ebm');
  });

  test('prefersFlats', () {
    bool flats(String k) => MusicKey.tryParse(k)!.prefersFlats;
    for (final k in ['F', 'Bb', 'Eb', 'Ab', 'Db', 'Dm', 'Gm', 'Cm', 'Fm']) {
      expect(flats(k), isTrue, reason: k);
    }
    for (final k in ['C', 'G', 'D', 'A', 'E', 'B', 'F#', 'Am', 'Em', 'C#m']) {
      expect(flats(k), isFalse, reason: k);
    }
  });

  test('transpose keeps major/minor and wraps', () {
    expect(MusicKey.tryParse('G')!.transpose(3).name, 'Bb');
    expect(MusicKey.tryParse('G')!.transpose(-1).name, 'F#');
    expect(MusicKey.tryParse('Am')!.transpose(1).name, 'Bbm');
    expect(MusicKey.tryParse('Am')!.transpose(3).name, 'Cm');
    expect(MusicKey.tryParse('A')!.transpose(-11).name, 'Bb');
  });

  test('fromChord', () {
    expect(MusicKey.fromChord(Chord.tryParse('F#m7')!).name, 'F#m');
    expect(MusicKey.fromChord(Chord.tryParse('Cmaj7')!).name, 'C');
  });
}
