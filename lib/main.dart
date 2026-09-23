import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/app/app.dart';

void main() {
  LicenseRegistry.addLicense(_fontLicenses);
  runApp(const ProviderScope(child: LibreTabApp()));
}

/// The bundled fonts' SIL Open Font Licenses, for the licenses page.
Stream<LicenseEntry> _fontLicenses() async* {
  const fonts = {
    'Atkinson Hyperlegible': 'AtkinsonHyperlegible',
    'Fraunces': 'Fraunces',
    'JetBrains Mono': 'JetBrainsMono',
  };
  for (final MapEntry(key: name, value: file) in fonts.entries) {
    final text = await rootBundle.loadString('assets/fonts/$file-OFL.txt');
    yield LicenseEntryWithLineBreaks([name], text);
  }
}
