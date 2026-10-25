import 'package:flutter/material.dart';

import '../../domain/focus_preset.dart';
import '../formatters.dart';

/// Reusable card for one focus preset. Long-press edits, but every gesture
/// also has a visible, labeled button.
class PresetCard extends StatelessWidget {
  const PresetCard({
    super.key,
    required this.preset,
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
  });

  final FocusPreset preset;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onStart,
        onLongPress: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                preset.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${preset.moodTag} · ${formatMinutes(preset.plannedSeconds)}',
                style: theme.textTheme.bodyMedium,
              ),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: 'Edit ${preset.label}',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete ${preset.label}',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow),
                    label: Text('Start ${preset.label}'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
