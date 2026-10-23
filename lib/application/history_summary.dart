import 'dart:isolate';

import '../domain/session_log.dart';

class HistorySummary {
  const HistorySummary({
    required this.finishedCount,
    required this.totalSeconds,
    required this.averageSeconds,
  });
  final int finishedCount;
  final int totalSeconds;
  final double averageSeconds;
}

Future<HistorySummary> summarizeInBackground(List<SessionLog> logs) {
  final values = logs
      .where((log) => log.status == SessionStatus.finished)
      .map((log) => log.completedSeconds)
      .toList(growable: false);
  return Isolate.run(() {
    final total = values.fold<int>(0, (sum, value) => sum + value);
    return HistorySummary(
      finishedCount: values.length,
      totalSeconds: total,
      averageSeconds: values.isEmpty ? 0 : total / values.length,
    );
  });
}
