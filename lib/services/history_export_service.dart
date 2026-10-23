import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/session_log.dart';

class HistoryExportService {
  Future<File> export(List<SessionLog> logs) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/adaptive_focus_history.csv');
    final buffer = StringBuffer(
      'started_at,completed_seconds,mood,status,source,note\n',
    );
    for (final log in logs) {
      buffer.writeln(
        [
          log.startedAt.toUtc().toIso8601String(),
          log.completedSeconds,
          _csv(log.moodTagSnapshot),
          log.status.name,
          _csv(log.source),
          _csv(log.note),
        ].join(','),
      );
    }
    return file.writeAsString(buffer.toString(), flush: true);
  }

  String _csv(String value) => '"${value.replaceAll('"', '""')}"';
}
