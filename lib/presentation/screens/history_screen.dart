import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/focus_preset.dart';
import '../../domain/session_log.dart';
import '../formatters.dart';
import '../state/ui_providers.dart';
import '../widgets/dialogs.dart';
import '../widgets/state_views.dart';
import 'session_log_form_screen.dart';

enum _StatusFilter { all, finished, reset }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  static const String _allMoods = 'All moods';

  _StatusFilter _status = _StatusFilter.all;
  String _mood = _allMoods;

  Future<void> _openForm(List<FocusPreset> presets, {SessionLog? log}) async {
    if (presets.isEmpty) {
      showMessage(context, 'Create a preset first, then add a log.');
      return;
    }
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SessionLogFormScreen(log: log, presets: presets),
      ),
    );
    if (saved == true && mounted) {
      refreshAppData(ref);
      showMessage(context, log == null ? 'Log added.' : 'Log updated.');
    }
  }

  Future<void> _delete(SessionLog log) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Delete session log?',
      message:
          'The ${formatMinutes(log.completedSeconds)} session from '
          '${formatDateTime(log.startedAt)} will be removed.',
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(sessionLogRepositoryProvider).delete(log.id!);
      if (!mounted) return;
      refreshAppData(ref);
      showMessage(context, 'Log deleted.');
    } catch (_) {
      if (mounted) showMessage(context, 'Could not delete the log.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(sessionLogsProvider);
    final presetsAsync = ref.watch(presetsProvider);
    final presets = presetsAsync.value;

    return Scaffold(
      appBar: AppBar(title: const Text('History and insights')),
      floatingActionButton: presets == null
          ? null
          : FloatingActionButton.extended(
              heroTag: null, // two tabs each have a FAB; skip the shared hero animation
              onPressed: () => _openForm(presets),
              icon: const Icon(Icons.add),
              label: const Text('Add log'),
            ),
      body: Builder(
        builder: (context) {
          if (logsAsync.hasError || presetsAsync.hasError) {
            return ErrorView(
              message: 'Session history could not be loaded.',
              onRetry: () => refreshAppData(ref),
            );
          }
          final logs = logsAsync.value;
          if (logs == null || presets == null) {
            return const LoadingView(label: 'Loading history');
          }
          if (logs.isEmpty) {
            return const MessageView(
              icon: Icons.history,
              title: 'No sessions yet',
              message: 'Finish a focus session or add a log to see it here.',
            );
          }
          return _buildList(context, logs, presets);
        },
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<SessionLog> logs,
    List<FocusPreset> presets,
  ) {
    final theme = Theme.of(context);
    final labels = {for (final p in presets) p.id: p.label};
    final moods = {...logs.map((log) => log.moodTagSnapshot)}.toList()..sort();
    if (_mood != _allMoods && !moods.contains(_mood)) _mood = _allMoods;

    final filtered = logs.where((log) {
      final statusOk = switch (_status) {
        _StatusFilter.all => true,
        _StatusFilter.finished => log.status == SessionStatus.finished,
        _StatusFilter.reset => log.status == SessionStatus.reset,
      };
      return statusOk && (_mood == _allMoods || log.moodTagSnapshot == _mood);
    }).toList();
    final finished = filtered
        .where((log) => log.status == SessionStatus.finished)
        .toList();
    final average = finished.isEmpty
        ? null
        : finished.fold<int>(0, (sum, log) => sum + log.completedSeconds) /
              finished.length;

    return RefreshIndicator(
      onRefresh: () async => refreshAppData(ref),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final filter in _StatusFilter.values)
                ChoiceChip(
                  label: Text(switch (filter) {
                    _StatusFilter.all => 'All',
                    _StatusFilter.finished => 'Finished',
                    _StatusFilter.reset => 'Reset',
                  }),
                  selected: _status == filter,
                  onSelected: (_) => setState(() => _status = filter),
                ),
              DropdownButton<String>(
                value: _mood,
                underline: const SizedBox.shrink(),
                items: [
                  for (final mood in [_allMoods, ...moods])
                    DropdownMenuItem(value: mood, child: Text(mood)),
                ],
                onChanged: (value) =>
                    setState(() => _mood = value ?? _allMoods),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                average == null
                    ? 'No finished sessions match this filter.'
                    : 'Average: ${formatMinutes(average)} '
                          '(${finished.length} finished '
                          '${finished.length == 1 ? 'session' : 'sessions'})',
                style: theme.textTheme.titleSmall,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const MessageView(
              icon: Icons.filter_alt_off_outlined,
              title: 'Nothing matches',
              message: 'Try a different filter.',
            ),
          for (final log in filtered)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                onTap: () => _openForm(presets, log: log),
                leading: Icon(
                  log.status == SessionStatus.finished
                      ? Icons.check_circle_outline
                      : Icons.restart_alt,
                  semanticLabel: log.status == SessionStatus.finished
                      ? 'Finished'
                      : 'Reset',
                ),
                title: Text(
                  '${labels[log.presetId] ?? 'Deleted preset'} · '
                  '${formatMinutes(log.completedSeconds)}',
                ),
                subtitle: Text(
                  [
                    formatDateTime(log.startedAt),
                    '${log.moodTagSnapshot} · '
                        '${log.status == SessionStatus.finished ? 'Finished' : 'Reset'}'
                        '${log.source == 'manual' ? ' · Manual' : ''}',
                    if (log.note.isNotEmpty) log.note,
                  ].join('\n'),
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit log',
                      onPressed: () => _openForm(presets, log: log),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete log',
                      onPressed: () => _delete(log),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
