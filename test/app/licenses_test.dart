import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/app/licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every bundled font has its SIL Open Font License', () async {
    final entries = await fontLicenses().toList();

    expect(
      entries.map((e) => e.packages.single),
      bundledFonts.keys.toList(),
    );
    for (final entry in entries) {
      final text = entry.paragraphs.map((p) => p.text).join('\n');
      expect(text, contains('SIL OPEN FONT LICENSE'));
    }
  });
}
