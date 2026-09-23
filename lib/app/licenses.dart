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

/// Tesseract and its language models ship in the Android app for camera
/// import (Apache License 2.0, which asks for this notice).
Stream<LicenseEntry> ocrLicenses() async* {
  yield const LicenseEntryWithLineBreaks(
    ['Tesseract OCR', 'Tesseract4Android', 'tessdata_fast (eng, spa)'],
    '''
Tesseract OCR: Copyright the Tesseract OCR authors.
Tesseract4Android: Copyright Adaptech s.r.o., Robert Pösel.
tessdata_fast language models (English, Spanish): Copyright the Tesseract OCR
authors.

Licensed under the Apache License, Version 2.0 (the "License"); you may not
use these files except in compliance with the License. You may obtain a copy
of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
License for the specific language governing permissions and limitations under
the License.

Used only in the Android app, for reading song sheets from photos.''',
  );
}
