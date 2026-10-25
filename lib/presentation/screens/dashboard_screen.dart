import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/focus_preset.dart';
import '../../domain/session_log.dart';
import '../formatters.dart';
import '../state/ui_providers.dart';
import '../widgets/dialogs.dart';
import '../widgets/preset_card.dart';
import '../widgets/scout_card.dart';
import '../widgets/state_views.dart';
import 'preset_form_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? _mood; // null means all moods

  Future<void> _openForm({
    FocusPreset? preset,
    int? minutes,
    String? mood,
  }) async {
    final defaultMinutes =
        ref.read(appSettingsProvider).value?.defaultMinutes ?? 25;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PresetFormScreen(
          preset: preset,
          initialMinutes: minutes ?? defaultMinutes,
          initialMood: mood,
        ),
      ),
    );
    if (saved == true && mounted) {
      refreshAppData(ref);
      showMessage(
        context,
        preset == null ? 'Preset added.' : 'Preset updated.',
      );
    }
  }

  Future<void> _delete(FocusPreset preset, List<SessionLog> logs) async {
    final linked = logs.where((log) => log.presetId == preset.id).length;
    if (linked > 0) {
      await showInfoDialog(
        context,
        title: 'Preset is in use',
        message:
            '"${preset.label}" has $linked session '
            '${linked == 1 ? 'log' : 'logs'}. Reassign or delete '
            '${linked == 1 ? 'it' : 'them'} in History first.',
      );
      return;
    }
    final confirmed = await confirmDelete(
      context,
      title: 'Delete preset?',
      message: '"${preset.label}" will be removed. This cannot be undone.',
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(presetRepositoryProvider).delete(preset.id!);
      if (!mounted) return;
      refreshAppData(ref);
      showMessage(context, 'Preset deleted.');
    } catch (_) {
      if (mounted) showMessage(context, 'Could not delete the preset.');
    }
  }

  void _start(FocusPreset preset) {
    ref.read(selectedPresetIdProvider.notifier).select(preset.id);
    ref.read(homeTabProvider.notifier).select(1);
  }

  @override
  Widget build(BuildContext context) {
    final presetsAsync = ref.watch(presetsProvider);
    final logsAsync = ref.watch(sessionLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Adaptive Focus Studio')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag:
            null, // two tabs each have a FAB; skip the shared hero animation
        onPressed: () => _openForm(mood: _mood),
        icon: const Icon(Icons.add),
        label: const Text('Add preset'),
      ),
      body: Builder(
        builder: (context) {
          if (presetsAsync.hasError || logsAsync.hasError) {
            return ErrorView(
              message: 'Your presets could not be loaded.',
              onRetry: () => refreshAppData(ref),
            );
          }
          final presets = presetsAsync.value;
          final logs = logsAsync.value;
          if (presets == null || logs == null) {
            return const LoadingView(label: 'Loading presets');
          }
          return _buildContent(context, presets, logs);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<FocusPreset> presets,
    List<SessionLog> logs,
  ) {
    final theme = Theme.of(context);
    final moods = {...presets.map((preset) => preset.moodTag)}.toList()..sort();
    if (_mood != null && !moods.contains(_mood)) _mood = null;

    final visible = _mood == null
        ? presets
        : presets.where((preset) => preset.moodTag == _mood).toList();
    final finished = logs
        .where((log) => log.status == SessionStatus.finished)
        .toList();
    final average = finished.isEmpty
        ? null
        : finished.fold<int>(0, (sum, log) => sum + log.completedSeconds) /
              finished.length;
    final scout = _mood == null
        ? null
        : scoutForMood(ref.read(sessionScoutProvider), logs, _mood!);

    return RefreshIndicator(
      onRefresh: () async => refreshAppData(ref),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.insights_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      average == null
                          ? 'No finished sessions yet. Your average will '
                                'appear here.'
                          : 'Average completed: ${formatMinutes(average)} '
                                '(${finished.length} '
                                '${finished.length == 1 ? 'session' : 'sessions'})',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Filter by mood', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _mood == null,
                onSelected: (_) => setState(() => _mood = null),
              ),
              for (final mood in moods)
                ChoiceChip(
                  label: Text(mood),
                  selected: _mood == mood,
                  onSelected: (_) => setState(() => _mood = mood),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ScoutCard(
            mood: _mood,
            result: scout,
            applyLabel: 'New preset with',
            onApply: (minutes) => _openForm(minutes: minutes, mood: _mood),
          ),
          const SizedBox(height: 16),
          Text(
            'Your focus presets',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (presets.isEmpty)
            const MessageView(
              icon: Icons.self_improvement_outlined,
              title: 'Start with your first preset',
              message: 'Tap Add preset to create a reusable focus session.',
            )
          else if (visible.isEmpty)
            const MessageView(
              icon: Icons.filter_alt_off_outlined,
              title: 'No presets for this mood',
              message: 'Choose another mood or add a new preset.',
            )
          else
            for (final preset in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PresetCard(
                  preset: preset,
                  onStart: () => _start(preset),
                  onEdit: () => _openForm(preset: preset),
                  onDelete: () => _delete(preset, logs),
                ),
              ),
        ],
      ),
    );
  }
}
