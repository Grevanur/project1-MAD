import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/sqlite_repositories.dart';
import '../domain/repositories.dart';
import '../services/reminder_service.dart';
import 'session_controller.dart';
import 'session_scout.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
final presetRepositoryProvider = Provider<FocusPresetRepository>(
  (ref) => SqliteFocusPresetRepository(ref.watch(databaseProvider)),
);
final sessionLogRepositoryProvider = Provider<SessionLogRepository>(
  (ref) => SqliteSessionLogRepository(ref.watch(databaseProvider)),
);
final sessionControllerProvider = Provider<SessionController>(
  (ref) => SessionController(),
);
final sessionScoutProvider = Provider<SessionScout>((ref) => SessionScout());
final reminderServiceProvider = Provider<ReminderService>(
  (ref) => ReminderService(),
);
