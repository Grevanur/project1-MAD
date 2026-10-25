import 'package:adaptive_focus_studio/domain/focus_preset.dart';
import 'package:adaptive_focus_studio/domain/session_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';

const presetList = [
  FocusPreset(id: 1, label: 'Deep Work', moodTag: 'Calm', plannedSeconds: 1500),
  FocusPreset(
    id: 2,
    label: 'Quick Review',
    moodTag: 'Focused',
    plannedSeconds: 900,
  ),
];

FakeSessionLogRepository seededLogs() => FakeSessionLogRepository([
  finishedLog(id: 1, presetId: 1, minutes: 25),
  SessionLog(
    id: 2,
    presetId: 2,
    startedAt: DateTime(2026, 10, 21, 14),
    completedSeconds: 5 * 60,
    moodTagSnapshot: 'Focused',
    status: SessionStatus.reset,
    source: 'timer',
  ),
]);

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('history lists, filters, and shows average with count', (
    tester,
  ) async {
    await pumpApp(
      tester,
      presets: FakePresetRepository(presetList),
      logs: seededLogs(),
    );
    await openTab(tester, 'History');

    expect(find.text('Deep Work · 25 min'), findsOneWidget);
    expect(find.text('Quick Review · 5 min'), findsOneWidget);
    expect(find.text('Average: 25 min (1 finished session)'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Reset'));
    await tester.pumpAndSettle();
    expect(find.text('Deep Work · 25 min'), findsNothing);
    expect(find.text('Quick Review · 5 min'), findsOneWidget);
  });

  testWidgets('deleting a log needs confirmation', (tester) async {
    final logs = seededLogs();
    await pumpApp(
      tester,
      presets: FakePresetRepository(presetList),
      logs: logs,
    );
    await openTab(tester, 'History');

    await tester.tap(find.byTooltip('Delete log').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(logs.items, hasLength(2));

    await tester.tap(find.byTooltip('Delete log').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(logs.items, hasLength(1));
  });

  testWidgets('editing a log updates its completed time', (tester) async {
    final logs = seededLogs();
    await pumpApp(
      tester,
      presets: FakePresetRepository(presetList),
      logs: logs,
    );
    await openTab(tester, 'History');

    // Newest first: the reset log from Oct 21 is the first row.
    await tester.tap(find.byTooltip('Edit log').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Completed time (minutes)'),
      '12',
    );
    await tester.tap(find.text('Save log'));
    await tester.pumpAndSettle();

    final edited = logs.items.firstWhere((log) => log.id == 2);
    expect(edited.completedSeconds, 12 * 60);
    expect(find.text('Quick Review · 12 min'), findsOneWidget);
  });

  testWidgets('adds a manual log and rejects zero minutes', (tester) async {
    final logs = FakeSessionLogRepository();
    await pumpApp(
      tester,
      presets: FakePresetRepository(presetList),
      logs: logs,
    );
    await openTab(tester, 'History');
    expect(find.text('No sessions yet'), findsOneWidget);

    await tester.tap(find.text('Add log'));
    await tester.pumpAndSettle();
    final minutes = find.widgetWithText(
      TextFormField,
      'Completed time (minutes)',
    );
    await tester.enterText(minutes, '0');
    await tester.tap(find.text('Save log'));
    await tester.pumpAndSettle();
    expect(
      find.text('Completed time must be greater than zero.'),
      findsOneWidget,
    );

    await tester.enterText(minutes, '15');
    await tester.tap(find.text('Save log'));
    await tester.pumpAndSettle();
    expect(logs.items, hasLength(1));
    expect(logs.items.single.source, 'manual');
    expect(logs.items.single.completedSeconds, 15 * 60);
  });

  testWidgets('settings persist after saving', (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'Settings');

    await tester.tap(find.text('Reduce motion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save settings'));
    await tester.pumpAndSettle();

    expect(find.text('Saved locally'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('reduced_motion'), isTrue);
    expect(prefs.getInt('default_minutes'), 25);
  });
}
