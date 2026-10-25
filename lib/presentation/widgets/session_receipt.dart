import 'package:flutter/material.dart';

import '../../domain/session_log.dart';
import '../formatters.dart';

/// Shows planned versus completed time after a session ends.
class SessionReceipt extends StatelessWidget {
  const SessionReceipt({
    super.key,
    required this.presetLabel,
    required this.plannedSeconds,
    required this.log,
    required this.saved,
  });

  final String presetLabel;
  final int plannedSeconds;
  final SessionLog log;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finished = log.status == SessionStatus.finished;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  finished ? Icons.check_circle_outline : Icons.restart_alt,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Session receipt',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(presetLabel),
            Text('Planned: ${formatMinutes(plannedSeconds)}'),
            Text('Completed: ${formatMinutes(log.completedSeconds)}'),
            Text('Started: ${formatDateTime(log.startedAt)}'),
            Text('Status: ${finished ? 'Finished' : 'Reset early'}'),
            const SizedBox(height: 4),
            Text(
              saved
                  ? 'Saved to History.'
                  : 'Not saved. Check storage and try again.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
