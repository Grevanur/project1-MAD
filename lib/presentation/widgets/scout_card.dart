import 'package:flutter/material.dart';

import '../state/ui_providers.dart';

/// Explains Session Scout's suggestion. It never applies itself: the user
/// must tap Apply, and can still edit the value afterwards.
class ScoutCard extends StatelessWidget {
  const ScoutCard({
    super.key,
    required this.mood,
    required this.result,
    this.onApply,
    this.applyLabel = 'Apply',
  });

  final String? mood;
  final ScoutResult? result;
  final ValueChanged<int>? onApply;
  final String applyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestion = result?.suggestion;
    final List<Widget> body;

    if (mood == null) {
      body = [const Text('Choose a mood to see a suggested starting length.')];
    } else if (suggestion == null) {
      body = [
        const Text(
          'Not enough history',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Session Scout needs 3 finished $mood sessions. '
          'You have ${result?.matchingCount ?? 0}.',
        ),
      ];
    } else {
      body = [
        Text(
          'Session Scout suggests ${suggestion.minutes} min',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text('${suggestion.explanation} Mood: $mood.'),
        const SizedBox(height: 4),
        Text(
          'This is a starting point, not a prediction of your attention.',
          style: theme.textTheme.bodySmall,
        ),
        if (onApply != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => onApply!(suggestion.minutes),
              icon: const Icon(Icons.check),
              label: Text('$applyLabel ${suggestion.minutes} min'),
            ),
          ),
        ],
      ];
    }

    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.explore_outlined,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
