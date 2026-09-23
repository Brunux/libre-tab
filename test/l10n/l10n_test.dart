import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/l10n/l10n.dart';

import '../helpers/pump_app.dart';

Map<String, dynamic> arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

Iterable<String> messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@'));

void main() {
  test('Spanish has exactly the same messages as English', () {
    expect(
      messageKeys(arb('es')).toSet(),
      messageKeys(arb('en')).toSet(),
    );
  });

  test('no message is empty', () {
    for (final locale in ['en', 'es']) {
      final messages = arb(locale);
      for (final key in messageKeys(messages)) {
        expect(
          (messages[key] as String).trim(),
          isNotEmpty,
          reason: '$locale: $key',
        );
      }
    }
  });

  test('English and Spanish are the only supported locales', () {
    expect(AppLocalizations.supportedLocales, [
      const Locale('en'),
      const Locale('es'),
    ]);
  });

  testWidgets('every screen shows Spanish on a Spanish device', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = [const Locale('es', 'MX')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final container = await pumpApp(tester);
    final router = container.read(routerProvider);

    // Songbook
    expect(find.text('Cancionero'), findsNWidgets(2));
    expect(find.textContaining('Tu cancionero está vacío'), findsOneWidget);
    expect(find.byTooltip('Ajustes'), findsOneWidget);

    router.go(Routes.tuner);
    await tester.pumpAndSettle();
    expect(find.text('Llegará en una próxima etapa.'), findsOneWidget);

    router.go(Routes.settings);
    await tester.pumpAndSettle();
    for (final text in ['Ajustes', 'TEMA', 'Oscuro', 'Noche roja', 'Claro']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }

    router.go(Routes.addSong);
    await tester.pumpAndSettle();
    expect(find.text('Agregar canción'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
    expect(find.byTooltip('Cancelar'), findsOneWidget);

    router.go(Routes.song('demo'));
    await tester.pumpAndSettle();
    expect(find.text('Canción'), findsOneWidget);
    expect(find.byTooltip('Cambiar tema'), findsOneWidget);
  });
}
