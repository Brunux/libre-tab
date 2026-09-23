import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/app/app.dart';
import 'package:libre_tab/app/licenses.dart';

void main() {
  LicenseRegistry.addLicense(fontLicenses);
  runApp(const ProviderScope(child: LibreTabApp()));
}
