import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/app/app.dart';
import 'package:libre_tab/app/licenses.dart';
import 'package:libre_tab/app/settings/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(fontLicenses);
  // Read saved settings before the first frame so the theme doesn't flash.
  final settings = await PrefsSettingsStore.load();
  runApp(
    ProviderScope(
      overrides: [settingsStoreProvider.overrideWithValue(settings)],
      child: const LibreTabApp(),
    ),
  );
}
