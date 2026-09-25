import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:libre_tab/core/database/app_database.dart';

/// A fresh in-memory database. Streams close synchronously so widget tests
/// don't end with pending timers.
AppDatabase testDatabase() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

/// Public-domain songs used across tests.
abstract final class SampleSongs {
  static const amazingGrace = '''
{title: Amazing Grace}
{artist: John Newton}
{key: G}

{start_of_verse}
A-[G]mazing [G7]grace, how [C]sweet the [G]sound
That [G]saved a wretch like [D]me
{end_of_verse}''';

  static const ohSusanna = '''
{title: Oh! Susanna}
{artist: Stephen Foster}
{key: C}
{capo: 2}

[C]I come from Alabama with my banjo on my [G]knee''';

  static const cancion = '''
{title: Canción de cuna}
{artist: Tradicional}

[Am]Duérmete mi niño, [E]duérmete mi amor''';
}
