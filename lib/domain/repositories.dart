import 'focus_preset.dart';
import 'session_log.dart';

abstract interface class FocusPresetRepository {
  Future<List<FocusPreset>> getAll();
  Future<FocusPreset?> getById(int id);
  Future<int> create(FocusPreset preset);
  Future<void> update(FocusPreset preset);
  Future<void> delete(int id);
}

abstract interface class SessionLogRepository {
  Future<List<SessionLog>> getAll();
  Future<List<SessionLog>> recentFinishedForMood(
    String moodTag, {
    int limit = 3,
  });
  Future<int> create(SessionLog log);
  Future<void> update(SessionLog log);
  Future<void> delete(int id);
  Future<double?> averageFinishedSeconds();
}
