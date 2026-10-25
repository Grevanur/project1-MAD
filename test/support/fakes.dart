import 'package:adaptive_focus_studio/application/providers.dart';
import 'package:adaptive_focus_studio/domain/focus_preset.dart';
import 'package:adaptive_focus_studio/domain/repositories.dart';
import 'package:adaptive_focus_studio/domain/session_log.dart';
import 'package:adaptive_focus_studio/presentation/app.dart';
import 'package:adaptive_focus_studio/services/reminder_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory repositories so widget tests never touch SQLite.
class FakePresetRepository implements FocusPresetRepository {
  FakePresetRepository([List<FocusPreset> seed = const []]) {
    for (final preset in seed) {
      _items.add(preset);
      if ((preset.id ?? 0) >= _nextId) _nextId = preset.id! + 1;
    }
  }

  final List<FocusPreset> _items = [];
  int _nextId = 1;

  List<FocusPreset> get items => List.unmodifiable(_items);

  @override
  Future<int> create(FocusPreset preset) async {
    final error =
        FocusPreset.validateLabel(preset.label) ??
        FocusPreset.validateDuration(preset.plannedSeconds);
    if (error != null) throw ArgumentError(error);
    final id = _nextId++;
    _items.add(
      FocusPreset(
        id: id,
        label: preset.label,
        moodTag: preset.moodTag,
        plannedSeconds: preset.plannedSeconds,
      ),
    );
    return id;
  }

  @override
  Future<void> delete(int id) async => _items.removeWhere((p) => p.id == id);

  @override
  Future<List<FocusPreset>> getAll() async => List.of(_items);

  @override
  Future<FocusPreset?> getById(int id) async =>
      _items.where((p) => p.id == id).firstOrNull;

  @override
  Future<void> update(FocusPreset preset) async {
    final index = _items.indexWhere((p) => p.id == preset.id);
    if (index < 0) throw StateError('Preset not found.');
    _items[index] = preset;
  }
}

class FakeSessionLogRepository implements SessionLogRepository {
  FakeSessionLogRepository([List<SessionLog> seed = const []]) {
    for (final log in seed) {
      _items.add(log);
      if ((log.id ?? 0) >= _nextId) _nextId = log.id! + 1;
    }
  }

  final List<SessionLog> _items = [];
  int _nextId = 1;

  List<SessionLog> get items => List.unmodifiable(_items);

  SessionLog _withId(SessionLog log, int id) => SessionLog(
    id: id,
    presetId: log.presetId,
    startedAt: log.startedAt,
    completedSeconds: log.completedSeconds,
    moodTagSnapshot: log.moodTagSnapshot,
    status: log.status,
    source: log.source,
    note: log.note,
  );

  @override
  Future<double?> averageFinishedSeconds() async {
    final finished = _items.where((l) => l.status == SessionStatus.finished);
    if (finished.isEmpty) return null;
    return finished.fold<int>(0, (s, l) => s + l.completedSeconds) /
        finished.length;
  }

  @override
  Future<int> create(SessionLog log) async {
    final id = _nextId++;
    _items.add(_withId(log, id));
    return id;
  }

  @override
  Future<void> delete(int id) async => _items.removeWhere((l) => l.id == id);

  @override
  Future<List<SessionLog>> getAll() async =>
      List.of(_items)..sort((a, b) => b.startedAt.compareTo(a.startedAt));

  @override
  Future<List<SessionLog>> recentFinishedForMood(
    String moodTag, {
    int limit = 3,
  }) async {
    final all = await getAll();
    return all
        .where(
          (l) =>
              l.status == SessionStatus.finished &&
              l.moodTagSnapshot == moodTag,
        )
        .take(limit)
        .toList();
  }

  @override
  Future<void> update(SessionLog log) async {
    final index = _items.indexWhere((l) => l.id == log.id);
    if (index < 0) throw StateError('Log not found.');
    _items[index] = log;
  }
}

class FakeReminderService extends ReminderService {
  FakeReminderService({this.permissionGranted = true});

  bool permissionGranted;
  int initializeCalls = 0;
  int permissionCalls = 0;
  int? scheduledId;
  DateTime? scheduledAt;
  String? scheduledLabel;
  int? canceledId;
  int cancelCalls = 0;

  @override
  Future<void> initialize() async => initializeCalls++;

  @override
  Future<bool> requestPermission() async {
    permissionCalls++;
    return permissionGranted;
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String presetLabel,
  }) async {
    scheduledId = id;
    scheduledAt = at;
    scheduledLabel = presetLabel;
  }

  @override
  Future<void> cancel(int id) async {
    cancelCalls++;
    canceledId = id;
  }
}

SessionLog finishedLog({
  int? id,
  int presetId = 1,
  int minutes = 25,
  String mood = 'Calm',
  DateTime? startedAt,
}) => SessionLog(
  id: id,
  presetId: presetId,
  startedAt: startedAt ?? DateTime(2026, 10, 20, 9),
  completedSeconds: minutes * 60,
  moodTagSnapshot: mood,
  status: SessionStatus.finished,
  source: 'timer',
);

/// Pumps the full app on a phone-sized portrait screen with fake storage.
Future<void> pumpApp(
  WidgetTester tester, {
  FakePresetRepository? presets,
  FakeSessionLogRepository? logs,
  Map<String, Object> preferences = const {},
  ReminderService? reminders,
  Size size = const Size(420, 900),
}) async {
  SharedPreferences.setMockInitialValues(preferences);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        presetRepositoryProvider.overrideWithValue(
          presets ?? FakePresetRepository(),
        ),
        sessionLogRepositoryProvider.overrideWithValue(
          logs ?? FakeSessionLogRepository(),
        ),
        if (reminders != null)
          reminderServiceProvider.overrideWithValue(reminders),
      ],
      child: const AdaptiveFocusApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Opens a dropdown field and picks an option.
Future<void> chooseDropdown(
  WidgetTester tester,
  Finder field,
  String option,
) async {
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}
