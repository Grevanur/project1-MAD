import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase({DatabaseFactory? factory, String? path})
    : _factory = factory ?? databaseFactory,
      _pathOverride = path;
  final DatabaseFactory _factory;
  final String? _pathOverride;
  Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    final path =
        _pathOverride ?? p.join(await getDatabasesPath(), 'adaptive_focus.db');
    return _database = await _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _createSchema,
      ),
    );
  }

  static Future<void> _createSchema(Database db, int version) async {
    await db.execute(
      'CREATE TABLE focus_presets (id INTEGER PRIMARY KEY AUTOINCREMENT, label TEXT NOT NULL CHECK(length(trim(label)) > 0), mood_tag TEXT NOT NULL, planned_seconds INTEGER NOT NULL CHECK(planned_seconds > 0))',
    );
    await db.execute(
      "CREATE TABLE session_logs (id INTEGER PRIMARY KEY AUTOINCREMENT, preset_id INTEGER NOT NULL, started_at TEXT NOT NULL, completed_seconds INTEGER NOT NULL CHECK(completed_seconds >= 0), mood_tag_snapshot TEXT NOT NULL, status TEXT NOT NULL CHECK(status IN ('finished', 'reset')), source TEXT NOT NULL, note TEXT NOT NULL DEFAULT '', FOREIGN KEY(preset_id) REFERENCES focus_presets(id) ON DELETE RESTRICT)",
    );
    await db.execute(
      'CREATE INDEX idx_session_logs_preset ON session_logs(preset_id)',
    );
    await db.execute(
      'CREATE INDEX idx_session_logs_mood ON session_logs(mood_tag_snapshot)',
    );
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
