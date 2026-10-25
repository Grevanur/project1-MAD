import 'package:adaptive_focus_studio/domain/focus_preset.dart';
import 'package:adaptive_focus_studio/domain/session_log.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

const oneMinute = FocusPreset(
  id: 1,
  label: 'Quick Review',
  moodTag: 'Focused',
  plannedSeconds: 60,
);

/// Opens the Focus tab from the preset card. Uses pump, not pumpAndSettle,
/// because a running timer keeps scheduling frames.
Future<void> openFocus(WidgetTester tester) async {
  await tester.tap(find.text('Start Quick Review'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> tapAndPump(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
}

void main() {
  testWidgets('start, pause, resume, then finish writes exactly one log', (
    tester,
  ) async {
    final logs = FakeSessionLogRepository();
    await pumpApp(
      tester,
      presets: FakePresetRepository([oneMinute]),
      logs: logs,
    );
    await openFocus(tester);
    expect(find.text('01:00'), findsOneWidget);

    await tapAndPump(tester, 'Start');
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('00:57'), findsOneWidget);

    await tapAndPump(tester, 'Pause');
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('00:57'), findsOneWidget);
    expect(find.text('Paused'), findsOneWidget);

    await tapAndPump(tester, 'Resume');
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('00:55'), findsOneWidget);

    // Two taps before the frame rebuilds: the second must be ignored.
    final finish = find.text('Finish');
    await tester.tap(finish);
    await tester.tap(finish, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(logs.items, hasLength(1));
    expect(logs.items.single.status, SessionStatus.finished);
    expect(logs.items.single.completedSeconds, 5);
    expect(logs.items.single.source, 'timer');
    expect(find.text('Session receipt'), findsOneWidget);
  });

  testWidgets('session finishes by itself when the countdown reaches zero', (
    tester,
  ) async {
    final logs = FakeSessionLogRepository();
    await pumpApp(
      tester,
      presets: FakePresetRepository([oneMinute]),
      logs: logs,
    );
    await openFocus(tester);

    await tapAndPump(tester, 'Start');
    await tester.pump(const Duration(seconds: 61));
    await tester.pumpAndSettle();

    expect(logs.items, hasLength(1));
    expect(logs.items.single.completedSeconds, 60);
    expect(find.text('Finished'), findsOneWidget);
  });

  testWidgets('reset during a session saves a reset log and restores time', (
    tester,
  ) async {
    final logs = FakeSessionLogRepository();
    await pumpApp(
      tester,
      presets: FakePresetRepository([oneMinute]),
      logs: logs,
    );
    await openFocus(tester);

    await tapAndPump(tester, 'Start');
    await tester.pump(const Duration(seconds: 4));
    await tapAndPump(tester, 'Reset');
    await tester.pumpAndSettle();

    expect(logs.items, hasLength(1));
    expect(logs.items.single.status, SessionStatus.reset);
    expect(logs.items.single.completedSeconds, 4);
    expect(find.text('01:00'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no presets', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Focus'));
    await tester.pumpAndSettle();

    expect(find.text('No presets yet'), findsOneWidget);
  });
}
