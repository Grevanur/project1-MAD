class ScoutSuggestion {
  const ScoutSuggestion({
    required this.minutes,
    required this.sampleCount,
    required this.explanation,
  });
  final int minutes;
  final int sampleCount;
  final String explanation;
}

class SessionScout {
  static const int baselineMinutes = 25;
  ScoutSuggestion? suggest(Iterable<int> completedSeconds) {
    final values = completedSeconds.where((v) => v > 0).take(3).toList()
      ..sort();
    if (values.length < 3) return null;
    final minutes = (values[1] / 60).round().clamp(10, 60);
    return ScoutSuggestion(
      minutes: minutes,
      sampleCount: 3,
      explanation: 'Based on the median of your three most recent finished sessions for this mood.',
    );
  }

  double meanAbsoluteError({
    required Iterable<int> suggestions,
    required Iterable<int> actualMinutes,
  }) {
    final predicted = suggestions.toList();
    final actual = actualMinutes.toList();
    if (predicted.isEmpty || predicted.length != actual.length) {
      throw ArgumentError(
        'Suggestion and actual case counts must match and be non-empty.',
      );
    }
    var total = 0;
    for (var i = 0; i < predicted.length; i++) {
      total += (predicted[i] - actual[i]).abs();
    }
    return total / predicted.length;
  }
}
