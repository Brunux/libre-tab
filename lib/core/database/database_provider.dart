import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/core/database/app_database.dart';

/// The app's single database. Tests override this with an in-memory one.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
