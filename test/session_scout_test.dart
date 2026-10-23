import 'package:adaptive_focus_studio/application/session_scout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final s = SessionScout();
  test('requires three cases', () => expect(s.suggest([1200, 1500]), isNull));
  test('uses median', () => expect(s.suggest([1200, 2400, 1800])?.minutes, 30));
  test('clamps low', () => expect(s.suggest([60, 120, 180])?.minutes, 10));
  test('clamps high', () => expect(s.suggest([4000, 5000, 6000])?.minutes, 60));
  test(
    'computes error',
    () => expect(
      s.meanAbsoluteError(suggestions: [25, 20], actualMinutes: [30, 18]),
      3.5,
    ),
  );
}
