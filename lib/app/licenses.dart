import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bundled fonts and the file holding each one's SIL Open Font License.
const bundledFonts = {
  'Atkinson Hyperlegible': 'assets/fonts/AtkinsonHyperlegible-OFL.txt',
  'Fraunces': 'assets/fonts/Fraunces-OFL.txt',
  'JetBrains Mono': 'assets/fonts/JetBrainsMono-OFL.txt',
};

/// The OFL requires the license to ship with the fonts; this puts each one
/// on Flutter's licenses page. Register with [LicenseRegistry.addLicense].
Stream<LicenseEntry> fontLicenses([AssetBundle? bundle]) async* {
  final assets = bundle ?? rootBundle;
  for (final MapEntry(key: name, value: path) in bundledFonts.entries) {
    yield LicenseEntryWithLineBreaks([name], await assets.loadString(path));
  }
}
