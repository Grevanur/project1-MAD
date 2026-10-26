import 'package:adaptive_focus_studio/domain/focus_preset.dart';
import 'package:flutter/material.dart' show FilledButton;
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

const deepWork = FocusPreset(
  id: 1,
  label: 'Deep Work',
  moodTag: 'Calm',
  plannedSeconds: 25 * 60,
);

void main() {
  testWidgets('swiping a history row asks before deleting', (tester) async {
    final logs = FakeSessionLogRepository([finishedLog(id: 1, minutes: 25)]);
    await pumpApp(
      tester,
      presets: FakePresetRepository([deepWork]),
      logs: logs,
    );
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    // Swipe left, then cancel: the log stays.
    await tester.drag(find.text('Deep Work · 25 min'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Delete session log?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(logs.items, hasLength(1));
    expect(find.text('Deep Work · 25 min'), findsOneWidget);

    // Swipe left, then confirm: the log is removed.
    await tester.drag(find.text('Deep Work · 25 min'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    // The swipe background also says "Delete", so target the dialog button.
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(logs.items, isEmpty);
    expect(find.text('No sessions yet'), findsOneWidget);
  });

  testWidgets('main screens render at 1.5x text size without overflow', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpApp(
      tester,
      presets: FakePresetRepository([deepWork]),
      logs: FakeSessionLogRepository([finishedLog(id: 1, minutes: 25)]),
    );
    expect(find.text('Deep Work'), findsOneWidget);

    for (final tab in ['Focus', 'History', 'Settings', 'Home']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      // Any RenderFlex overflow would surface here as an exception.
      expect(tester.takeException(), isNull, reason: 'Overflow on $tab');
    }
  });
}
