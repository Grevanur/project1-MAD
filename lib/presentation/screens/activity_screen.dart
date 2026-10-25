import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../application/session_controller.dart';
import '../../domain/focus_preset.dart';
import '../../domain/session_log.dart';
import '../formatters.dart';
import '../state/ui_providers.dart';
import '../widgets/dialogs.dart';
import '../widgets/session_receipt.dart';
import '../widgets/state_views.dart';

/// Runs one focus session. Timer rules live in [SessionController]; this
/// widget only drives the one-second ticker and shows the state.
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key, this.tick = const Duration(seconds: 1)});

  /// How often the timer advances by one second. Tests may shorten it.
  final Duration tick;

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  late final SessionController _controller;
  Timer? _ticker;
  FocusPreset? _activePreset;
  DateTime? _startedAt;
  bool _saving = false;
  SessionLog? _receipt;
  String _receiptLabel = '';
  int _receiptPlanned = 0;
  bool _receiptSaved = false;

  SessionState get _session => _controller.state;
  bool get _isActive =>
      _session.phase == TimerPhase.running ||
      _session.phase == TimerPhase.paused;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(sessionControllerProvider);
    // A session left over from a disposed screen has no ticker; start clean.
    _controller.reset();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(widget.tick, (_) => _onTick());
  }

  void _onTick() {
    if (!mounted || _session.phase != TimerPhase.running) return;
    _controller.tick();
    if (_session.remainingSeconds == 0) {
      _finish();
    } else {
      setState(() {});
    }
  }

  void _start(FocusPreset preset) {
    if (_isActive) return;
    try {
      _controller.reset();
      _controller.start(preset.plannedSeconds);
    } on Object {
      showMessage(context, 'This preset needs a positive duration.');
      return;
    }
    setState(() {
      _activePreset = preset;
      _startedAt = DateTime.now();
      _receipt = null;
    });
    _startTicker();
  }

  void _pause() {
    if (_session.phase != TimerPhase.running) return;
    _ticker?.cancel();
    setState(_controller.pause);
  }

  void _resume() {
    if (_session.phase != TimerPhase.paused) return;
    setState(_controller.resume);
    _startTicker();
  }

  /// Finishing is guarded twice: by [_saving] here and by the controller,
  /// which refuses a second finish. Only one log is ever written.
  Future<void> _finish() async {
    if (_saving || !_isActive) return;
    _ticker?.cancel();
    final preset = _activePreset;
    final startedAt = _startedAt;
    final int completed;
    try {
      completed = _controller.finish();
    } on StateError {
      return;
    }
    if (preset == null || startedAt == null) return;
    await _saveLog(preset, startedAt, completed, SessionStatus.finished);
  }

  Future<void> _reset() async {
    if (_saving) return;
    _ticker?.cancel();
    final wasActive = _isActive;
    final elapsed = _session.elapsedSeconds;
    final preset = _activePreset;
    final startedAt = _startedAt;
    _controller.reset();
    setState(() {
      _activePreset = null;
      _startedAt = null;
      _receipt = null;
    });
    if (wasActive && elapsed > 0 && preset != null && startedAt != null) {
      await _saveLog(preset, startedAt, elapsed, SessionStatus.reset);
    }
  }

  Future<void> _saveLog(
    FocusPreset preset,
    DateTime startedAt,
    int seconds,
    SessionStatus status,
  ) async {
    final log = SessionLog(
      presetId: preset.id ?? 0,
      startedAt: startedAt,
      completedSeconds: seconds,
      moodTagSnapshot: preset.moodTag,
      status: status,
      source: 'timer',
    );
    setState(() => _saving = true);
    var saved = false;
    try {
      if (preset.id == null) throw StateError('Preset has no id.');
      await ref.read(sessionLogRepositoryProvider).create(log);
      saved = true;
    } catch (_) {
      saved = false;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _receipt = log;
      _receiptLabel = preset.label;
      _receiptPlanned = preset.plannedSeconds;
      _receiptSaved = saved;
    });
    if (saved) {
      refreshAppData(ref);
      showMessage(
        context,
        status == SessionStatus.finished
            ? 'Session finished and saved to History.'
            : 'Partial session saved as reset.',
      );
    } else {
      showMessage(context, 'Could not save this session.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final presetsAsync = ref.watch(presetsProvider);
    final selectedId = ref.watch(selectedPresetIdProvider);
    final reduceMotion =
        (ref.watch(appSettingsProvider).value?.reducedMotion ?? false) ||
        MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Focus session')),
      body: Builder(
        builder: (context) {
          if (presetsAsync.hasError) {
            return ErrorView(
              message: 'Presets could not be loaded.',
              onRetry: () => refreshAppData(ref),
            );
          }
          final presets = presetsAsync.value;
          if (presets == null) return const LoadingView();
          if (presets.isEmpty && !_isActive) {
            return MessageView(
              icon: Icons.timer_outlined,
              title: 'No presets yet',
              message: 'Create a focus preset on Home first.',
              action: FilledButton(
                onPressed: () => ref.read(homeTabProvider.notifier).select(0),
                child: const Text('Go to Home'),
              ),
            );
          }
          final selected =
              _activePreset ??
              presets.where((p) => p.id == selectedId).firstOrNull ??
              presets.first;
          return _buildSession(context, presets, selected, reduceMotion);
        },
      ),
    );
  }

  Widget _buildSession(
    BuildContext context,
    List<FocusPreset> presets,
    FocusPreset selected,
    bool reduceMotion,
  ) {
    final theme = Theme.of(context);
    final phase = _session.phase;
    final planned = phase == TimerPhase.idle
        ? selected.plannedSeconds
        : _session.plannedSeconds;
    final remaining = phase == TimerPhase.idle
        ? selected.plannedSeconds
        : _session.remainingSeconds;
    final progress = planned == 0 ? 0.0 : 1 - remaining / planned;
    final status = switch (phase) {
      TimerPhase.idle => 'Ready when you are',
      TimerPhase.running => 'In progress',
      TimerPhase.paused => 'Paused',
      TimerPhase.finished => 'Finished',
    };

    final picker = DropdownButtonFormField<int>(
      isExpanded: true,
      key: ValueKey('preset-picker-${selected.id}'),
      initialValue: selected.id,
      decoration: const InputDecoration(
        labelText: 'Focus preset',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final preset in presets)
          if (preset.id != null)
            DropdownMenuItem(
              value: preset.id,
              child: Text(
                '${preset.label} · ${formatMinutes(preset.plannedSeconds)}',
              ),
            ),
      ],
      onChanged: _isActive
          ? null
          : (id) {
              ref.read(selectedPresetIdProvider.notifier).select(id);
              setState(() {
                _controller.reset();
                _receipt = null;
              });
            },
    );

    final dial = Semantics(
      label: '${selected.label}. $status. ${spokenClock(remaining)}',
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: progress),
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 450),
                  builder: (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 10,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatClock(remaining),
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(status),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final controls = Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        if (phase == TimerPhase.idle || phase == TimerPhase.finished)
          FilledButton.icon(
            onPressed: _saving ? null : () => _start(selected),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start'),
          ),
        if (phase == TimerPhase.running)
          FilledButton.icon(
            onPressed: _pause,
            icon: const Icon(Icons.pause),
            label: const Text('Pause'),
          ),
        if (phase == TimerPhase.paused)
          FilledButton.icon(
            onPressed: _resume,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Resume'),
          ),
        if (_isActive)
          FilledButton.tonalIcon(
            onPressed: _saving ? null : _finish,
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Finish'),
          ),
        OutlinedButton.icon(
          onPressed: phase == TimerPhase.idle || _saving ? null : _reset,
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reset'),
        ),
      ],
    );

    final receipt = AnimatedSwitcher(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 300),
      child: _receipt == null
          ? const SizedBox.shrink()
          : SessionReceipt(
              key: ValueKey(_receipt),
              presetLabel: _receiptLabel,
              plannedSeconds: _receiptPlanned,
              log: _receipt!,
              saved: _receiptSaved,
            ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        if (wide) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Center(child: dial)),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      picker,
                      const SizedBox(height: 24),
                      controls,
                      const SizedBox(height: 16),
                      receipt,
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                picker,
                const SizedBox(height: 24),
                Center(child: dial),
                const SizedBox(height: 24),
                controls,
                const SizedBox(height: 16),
                receipt,
              ],
            ),
          ),
        );
      },
    );
  }
}
