import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/app/app.dart';
import 'package:libre_tab/app/router.dart';

/// Pumps the whole app and returns its provider container, so tests can
/// read state and drive the router.
Future<ProviderContainer> pumpApp(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const LibreTabApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// The router's current location. Pushed routes (Add song, Settings) don't
/// change it; check the screen instead.
String currentPath(ProviderContainer container) =>
    container.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

Finder navItem(String label) =>
    find.widgetWithText(NavigationDestination, label);

/// Every screen and how to reach it from a fresh app.
const Map<String, String> screenPaths = {
  'Songbook': Routes.songbook,
  'Tuner': Routes.tuner,
  'Settings': Routes.settings,
  'Add song': Routes.addSong,
  'Song view': '/songs/demo',
};
