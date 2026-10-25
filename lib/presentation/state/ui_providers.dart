import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../application/providers.dart';
import '../../application/session_scout.dart';
import '../../application/settings_store.dart';
import '../../domain/focus_preset.dart';
import '../../domain/session_log.dart';

/// Fixed mood tags so filtering and Session Scout matching stay consistent.
const List<String> kMoodOptions = [
  'Calm',
  'Focused',
  'Energized',
  'Tired',
  'Stressed',
];

/// Bumped after every create, update, or delete so every screen reloads
/// from the repositories instead of keeping its own copy of the data.
class DataVersion extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final dataVersionProvider = NotifierProvider<DataVersion, int>(DataVersion.new);

final presetsProvider = FutureProvider<List<FocusPreset>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(presetRepositoryProvider).getAll();
});

final sessionLogsProvider = FutureProvider<List<SessionLog>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(sessionLogRepositoryProvider).getAll();
});

final settingsStoreProvider = FutureProvider<SettingsStore>((ref) async {
  return SettingsStore(await SharedPreferences.getInstance());
});

final appSettingsProvider = FutureProvider<AppSettings>((ref) async {
  ref.watch(dataVersionProvider);
  final store = await ref.watch(settingsStoreProvider.future);
  return store.load();
});

/// Which bottom-navigation tab is visible.
class HomeTab extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final homeTabProvider = NotifierProvider<HomeTab, int>(HomeTab.new);

/// The preset chosen on the dashboard for the Activity screen.
class SelectedPreset extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? presetId) => state = presetId;
}

final selectedPresetIdProvider = NotifierProvider<SelectedPreset, int?>(
  SelectedPreset.new,
);

void refreshAppData(WidgetRef ref) =>
    ref.read(dataVersionProvider.notifier).bump();

/// Result of running Session Scout for one mood.
class ScoutResult {
  const ScoutResult({required this.suggestion, required this.matchingCount});

  final ScoutSuggestion? suggestion;
  final int matchingCount;
}

ScoutResult scoutForMood(
  SessionScout scout,
  List<SessionLog> logs,
  String mood,
) {
  final matching =
      logs
          .where(
            (log) =>
                log.status == SessionStatus.finished &&
                log.moodTagSnapshot == mood &&
                log.completedSeconds > 0,
          )
          .toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  return ScoutResult(
    suggestion: scout.suggest(matching.map((log) => log.completedSeconds)),
    matchingCount: matching.length,
  );
}
