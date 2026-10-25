import 'package:adaptive_focus_studio/domain/session_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/fakes.dart';

/// End-to-end flow: create a preset, run it, finish once, see it in History.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('create preset, finish a session, review it in History', (
    tester,
  ) async {
    final presets = FakePresetRepository();
    final logs = FakeSessionLogRepository();
    await pumpApp(tester, presets: presets, logs: logs);

    await tester.tap(find.text('Add preset'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Label'),
      'Flow Test',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await chooseDropdown(
      tester,
      find.byType(DropdownButtonFormField<String>),
      'Focused',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Duration (minutes)'),
      '1',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Save preset'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save preset'));
    await tester.pumpAndSettle();
    expect(presets.items, hasLength(1));

    await tester.tap(find.text('Start Flow Test'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Start'));
    await tester.pump(const Duration(seconds: 10));
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(logs.items, hasLength(1));
    expect(logs.items.single.status, SessionStatus.finished);
    expect(logs.items.single.completedSeconds, 10);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Flow Test · 10 sec'), findsOneWidget);
    expect(find.text('Average: 10 sec (1 finished session)'), findsOneWidget);
  });
}
