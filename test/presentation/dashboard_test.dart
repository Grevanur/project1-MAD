import 'package:adaptive_focus_studio/domain/focus_preset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

const deepWork = FocusPreset(
  id: 1,
  label: 'Deep Work',
  moodTag: 'Calm',
  plannedSeconds: 25 * 60,
);

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('preset form shows errors for empty label, mood, and zero '
      'duration, then saves once corrected', (tester) async {
    final presets = FakePresetRepository();
    await pumpApp(tester, presets: presets);

    await tester.tap(find.text('Add preset'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Duration (minutes)'),
      '0',
    );
    await tapVisible(tester, find.text('Save preset'));

    expect(find.text('Enter a preset label.'), findsOneWidget);
    expect(find.text('Choose a mood tag.'), findsOneWidget);
    expect(find.text('Duration must be greater than zero.'), findsOneWidget);
    expect(presets.items, isEmpty);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Label'),
      'Deep Work',
    );
    await chooseDropdown(
      tester,
      find.byType(DropdownButtonFormField<String>),
      'Calm',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Duration (minutes)'),
      '20',
    );
    await tapVisible(tester, find.text('Save preset'));

    expect(presets.items, hasLength(1));
    expect(presets.items.single.plannedSeconds, 20 * 60);
    expect(find.text('Deep Work'), findsOneWidget);
    expect(find.text('Calm · 20 min'), findsOneWidget);
  });

  testWidgets('shows the average with its sample count', (tester) async {
    await pumpApp(
      tester,
      presets: FakePresetRepository([deepWork]),
      logs: FakeSessionLogRepository([
        finishedLog(id: 1, minutes: 20),
        finishedLog(id: 2, minutes: 25),
      ]),
    );

    expect(
      find.text('Average completed: 22.5 min (2 sessions)'),
      findsOneWidget,
    );
  });

  testWidgets('Session Scout says when there is not enough history', (
    tester,
  ) async {
    await pumpApp(
      tester,
      presets: FakePresetRepository([deepWork]),
      logs: FakeSessionLogRepository([finishedLog(id: 1, minutes: 20)]),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Calm'));
    await tester.pumpAndSettle();

    expect(find.text('Not enough history'), findsOneWidget);
    expect(
      find.text('Session Scout needs 3 finished Calm sessions. You have 1.'),
      findsOneWidget,
    );
  });

  testWidgets('Session Scout suggestion fills the form only after Apply', (
    tester,
  ) async {
    await pumpApp(
      tester,
      presets: FakePresetRepository([deepWork]),
      logs: FakeSessionLogRepository([
        finishedLog(id: 1, minutes: 30, startedAt: DateTime(2026, 10, 20)),
        finishedLog(id: 2, minutes: 40, startedAt: DateTime(2026, 10, 21)),
        finishedLog(id: 3, minutes: 35, startedAt: DateTime(2026, 10, 22)),
      ]),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Calm'));
    await tester.pumpAndSettle();
    expect(find.text('Session Scout suggests 35 min'), findsOneWidget);

    // Open an edit form: the duration stays at 25 until Apply is tapped.
    await tapVisible(tester, find.byTooltip('Edit Deep Work'));
    final duration = find.widgetWithText(TextFormField, 'Duration (minutes)');
    expect(tester.widget<TextFormField>(duration).controller!.text, '25');
    await tapVisible(tester, find.text('Apply 35 min'));
    expect(tester.widget<TextFormField>(duration).controller!.text, '35');
  });

  testWidgets('deleting a preset that has logs is blocked', (tester) async {
    final presets = FakePresetRepository([deepWork]);
    await pumpApp(
      tester,
      presets: presets,
      logs: FakeSessionLogRepository([finishedLog(id: 1)]),
    );

    await tapVisible(tester, find.byTooltip('Delete Deep Work'));

    expect(find.text('Preset is in use'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(presets.items, hasLength(1));
  });

  testWidgets('deleting an unused preset asks for confirmation', (
    tester,
  ) async {
    final presets = FakePresetRepository([deepWork]);
    await pumpApp(tester, presets: presets);

    await tapVisible(tester, find.byTooltip('Delete Deep Work'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(presets.items, hasLength(1));

    await tapVisible(tester, find.byTooltip('Delete Deep Work'));
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(presets.items, isEmpty);
    expect(find.text('Start with your first preset'), findsOneWidget);
  });
}
