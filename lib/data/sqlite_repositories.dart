import 'package:sqflite/sqflite.dart';

import '../domain/focus_preset.dart';
import '../domain/repositories.dart';
import '../domain/session_log.dart';
import 'app_database.dart';

class SqliteFocusPresetRepository implements FocusPresetRepository {
  SqliteFocusPresetRepository(this._appDatabase);
  final AppDatabase _appDatabase;
  Future<Database> get _db => _appDatabase.database;
  @override
  Future<int> create(FocusPreset preset) async {
    final error =
        FocusPreset.validateLabel(preset.label) ??
        FocusPreset.validateDuration(preset.plannedSeconds);
    if (error != null) throw ArgumentError(error);
    final values = preset.toMap()..remove('id');
    return (await _db).insert('focus_presets', values);
  }

  @override
  Future<void> delete(int id) async {
    final count = await (await _db).delete(
      'focus_presets',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count != 1) throw StateError('Preset $id was not found.');
  }

  @override
  Future<List<FocusPreset>> getAll() async {
    final rows = await (await _db).query(
      'focus_presets',
      orderBy: 'label COLLATE NOCASE',
    );
    return rows.map(FocusPreset.fromMap).toList(growable: false);
  }

  @override
  Future<FocusPreset?> getById(int id) async {
    final rows = await (await _db).query(
      'focus_presets',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : FocusPreset.fromMap(rows.single);
  }

  @override
  Future<void> update(FocusPreset preset) async {
    if (preset.id == null) throw ArgumentError('An id is required for update.');
    final values = preset.toMap()..remove('id');
    final count = await (await _db).update(
      'focus_presets',
      values,
      where: 'id = ?',
      whereArgs: [preset.id],
    );
    if (count != 1) throw StateError('Preset ${preset.id} was not found.');
  }
}

class SqliteSessionLogRepository implements SessionLogRepository {
  SqliteSessionLogRepository(this._appDatabase);
  final AppDatabase _appDatabase;
  Future<Database> get _db => _appDatabase.database;
  @override
  Future<double?> averageFinishedSeconds() async {
    final rows = await (await _db).rawQuery(
      "SELECT AVG(completed_seconds) AS average FROM session_logs WHERE status = 'finished'",
    );
    return (rows.single['average'] as num?)?.toDouble();
  }

  @override
  Future<int> create(SessionLog log) async {
    final values = log.toMap()..remove('id');
    return (await _db).insert('session_logs', values);
  }

  @override
  Future<void> delete(int id) async {
    final count = await (await _db).delete(
      'session_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count != 1) throw StateError('Session log $id was not found.');
  }

  @override
  Future<List<SessionLog>> getAll() async {
    final rows = await (await _db).query(
      'session_logs',
      orderBy: 'started_at DESC',
    );
    return rows.map(SessionLog.fromMap).toList(growable: false);
  }

  @override
  Future<List<SessionLog>> recentFinishedForMood(
    String moodTag, {
    int limit = 3,
  }) async {
    final rows = await (await _db).query(
      'session_logs',
      where: "status = 'finished' AND mood_tag_snapshot = ?",
      whereArgs: [moodTag],
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return rows.map(SessionLog.fromMap).toList(growable: false);
  }

  @override
  Future<void> update(SessionLog log) async {
    if (log.id == null) throw ArgumentError('An id is required for update.');
    final values = log.toMap()..remove('id');
    final count = await (await _db).update(
      'session_logs',
      values,
      where: 'id = ?',
      whereArgs: [log.id],
    );
    if (count != 1) throw StateError('Session log ${log.id} was not found.');
  }
}
