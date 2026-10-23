import 'package:adaptive_focus_studio/data/app_database.dart';
import 'package:adaptive_focus_studio/data/sqlite_repositories.dart';
import 'package:adaptive_focus_studio/domain/focus_preset.dart';
import 'package:adaptive_focus_studio/domain/session_log.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase db;
  late SqliteFocusPresetRepository presets;
  late SqliteSessionLogRepository logs;
  setUp(() {
    db = AppDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    presets = SqliteFocusPresetRepository(db);
    logs = SqliteSessionLogRepository(db);
  });
  tearDown(() => db.close());
  test('creates and reads preset', () async {
    final id = await presets.create(
      const FocusPreset(label: 'Study', moodTag: 'calm', plannedSeconds: 1500),
    );
    expect((await presets.getById(id))?.label, 'Study');
  });
  test('updates preset', () async {
    final id = await presets.create(
      const FocusPreset(label: 'Study', moodTag: 'calm', plannedSeconds: 1500),
    );
    await presets.update(
      FocusPreset(
        id: id,
        label: 'Deep Study',
        moodTag: 'calm',
        plannedSeconds: 1800,
      ),
    );
    expect((await presets.getById(id))?.plannedSeconds, 1800);
  });
  test('restricts deletion with log', () async {
    final id = await presets.create(
      const FocusPreset(label: 'Study', moodTag: 'calm', plannedSeconds: 1500),
    );
    await logs.create(
      SessionLog(
        presetId: id,
        startedAt: DateTime.utc(2026),
        completedSeconds: 1200,
        moodTagSnapshot: 'calm',
        status: SessionStatus.finished,
        source: 'manual',
      ),
    );
    expect(() => presets.delete(id), throwsA(anything));
  });
  test('calculates average', () async {
    final id = await presets.create(
      const FocusPreset(label: 'Study', moodTag: 'calm', plannedSeconds: 1500),
    );
    for (final seconds in [600, 1200]) {
      await logs.create(
        SessionLog(
          presetId: id,
          startedAt: DateTime.utc(2026),
          completedSeconds: seconds,
          moodTagSnapshot: 'calm',
          status: SessionStatus.finished,
          source: 'manual',
        ),
      );
    }
    expect(await logs.averageFinishedSeconds(), 900);
  });
}
