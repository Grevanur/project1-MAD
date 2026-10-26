import 'package:adaptive_focus_studio/application/session_scout.dart';
import 'package:adaptive_focus_studio/domain/session_log.dart';
import 'package:adaptive_focus_studio/presentation/state/ui_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

/// The five required helper case types documented in AI_FEATURE.md:
/// normal, no-data, invalid, boundary/tie/outlier, and counterexample.
void main() {
  final scout = SessionScout();

  List<SessionLog> calm(List<int> minutes) => [
    for (var i = 0; i < minutes.length; i++)
      finishedLog(
        id: i + 1,
        minutes: minutes[i],
        startedAt: DateTime(2026, 10, 20 + i),
      ),
  ];

  test('normal: median of three recent finished sessions', () {
    final result = scoutForMood(scout, calm([20, 25, 30]), 'Calm');
    expect(result.suggestion?.minutes, 25);
    expect(result.matchingCount, 3);
  });

  test('no data: fewer than three matches gives no suggestion', () {
    final result = scoutForMood(scout, calm([20, 25]), 'Calm');
    expect(result.suggestion, isNull);
    expect(result.matchingCount, 2);
  });

  test('no data: other moods never count as matches', () {
    final result = scoutForMood(scout, calm([20, 25, 30]), 'Focused');
    expect(result.suggestion, isNull);
    expect(result.matchingCount, 0);
  });

  test('invalid: zero-length and reset sessions are excluded', () {
    final logs = [
      ...calm([20, 25]),
      finishedLog(id: 10, minutes: 0, startedAt: DateTime(2026, 10, 25)),
      SessionLog(
        id: 11,
        presetId: 1,
        startedAt: DateTime(2026, 10, 26),
        completedSeconds: 40 * 60,
        moodTagSnapshot: 'Calm',
        status: SessionStatus.reset,
        source: 'timer',
      ),
    ];
    final result = scoutForMood(scout, logs, 'Calm');
    expect(result.suggestion, isNull);
    expect(result.matchingCount, 2);
  });

  test('boundary: short history is clamped up to 10 minutes', () {
    expect(
      scoutForMood(scout, calm([8, 9, 12]), 'Calm').suggestion?.minutes,
      10,
    );
  });

  test('tie: repeated values still give one deterministic median', () {
    expect(
      scoutForMood(scout, calm([20, 20, 30]), 'Calm').suggestion?.minutes,
      20,
    );
  });

  test('outlier: one very long session does not move the median', () {
    expect(
      scoutForMood(scout, calm([25, 26, 120]), 'Calm').suggestion?.minutes,
      26,
    );
  });

  test('only the three most recent matching sessions are used', () {
    // Oldest session (90 min) is ignored; recent ones are 20, 25, 30.
    final result = scoutForMood(scout, calm([90, 20, 25, 30]), 'Calm');
    expect(result.suggestion?.minutes, 25);
    expect(result.matchingCount, 4);
  });

  test('counterexample: a habit change makes the fixed baseline win', () {
    final suggestion = scoutForMood(
      scout,
      calm([55, 60, 65]),
      'Calm',
    ).suggestion!.minutes;
    const actual = 25;
    final scoutError = scout.meanAbsoluteError(
      suggestions: [suggestion],
      actualMinutes: [actual],
    );
    final baselineError = scout.meanAbsoluteError(
      suggestions: [SessionScout.baselineMinutes],
      actualMinutes: [actual],
    );
    expect(scoutError, 35);
    expect(baselineError, 0);
  });
}
