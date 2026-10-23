import 'package:adaptive_focus_studio/presentation/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the foundation handoff screen', (tester) async {
    await tester.pumpWidget(const AdaptiveFocusApp());
    expect(find.text('Adaptive Focus Studio'), findsOneWidget);
    expect(find.textContaining('foundation is ready'), findsOneWidget);
  });
}
