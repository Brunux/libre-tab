import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/app/app.dart';
import 'package:libre_tab/app/licenses.dart';
import 'package:libre_tab/app/settings/settings_store.dart';
import 'package:libre_tab/features/library/data/starter_songs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(fontLicenses);
  // Read saved settings before the first frame so the theme doesn't flash.
  final settings = await PrefsSettingsStore.load();
  final container = ProviderContainer(
    overrides: [settingsStoreProvider.overrideWithValue(settings)],
  );
  // First launch: fill the empty songbook with the starter songs. Not in
  // LibreTabApp, so widget tests start from an empty songbook.
  unawaited(
    container.read(starterSongsProvider).addOnFirstLaunch(settings),
  );
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const LibreTabApp(),
    ),
  );
}
