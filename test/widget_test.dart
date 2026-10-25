import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('opens on the dashboard with four navigation destinations', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Adaptive Focus Studio'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    for (final label in ['Home', 'Focus', 'History', 'Settings']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Start with your first preset'), findsOneWidget);
    expect(find.text('Add preset'), findsOneWidget);
  });

  testWidgets('uses a navigation rail in landscape', (tester) async {
    await pumpApp(tester, size: const Size(900, 420));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
