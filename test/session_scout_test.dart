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

  test('held-out scenarios beat the fixed baseline', () {
    const histories = [
      [20, 25, 30],
      [15, 20, 35],
      [30, 35, 40],
      [8, 9, 12],
      [55, 65, 70],
    ];
    const actual = [27, 22, 33, 11, 58];
    final suggestions = histories
        .map(
          (minutes) => s.suggest(minutes.map((value) => value * 60))!.minutes,
        )
        .toList();

    expect(
      s.meanAbsoluteError(suggestions: suggestions, actualMinutes: actual),
      1.8,
    );
    expect(
      s.meanAbsoluteError(
        suggestions: List.filled(actual.length, SessionScout.baselineMinutes),
        actualMinutes: actual,
      ),
      12,
    );
  });
}
