import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/focus_preset.dart';
import '../../domain/session_log.dart';
import '../formatters.dart';
import '../widgets/dialogs.dart';

/// Add a manual log or edit an existing one. Pops `true` after saving.
class SessionLogFormScreen extends ConsumerStatefulWidget {
  const SessionLogFormScreen({super.key, this.log, required this.presets});

  final SessionLog? log;
  final List<FocusPreset> presets;

  @override
  ConsumerState<SessionLogFormScreen> createState() =>
      _SessionLogFormScreenState();
}

class _SessionLogFormScreenState extends ConsumerState<SessionLogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _minutesController;
  late final TextEditingController _noteController;
  late String _initialMinutesText;
  int? _presetId;
  late DateTime _startedAt;
  late SessionStatus _status;
  bool _saving = false;

  bool get _isEditing => widget.log != null;

  @override
  void initState() {
    super.initState();
    final log = widget.log;
    final ids = widget.presets.map((p) => p.id).toSet();
    _presetId = log != null && ids.contains(log.presetId)
        ? log.presetId
        : widget.presets.firstOrNull?.id;
    _startedAt = (log?.startedAt ?? DateTime.now()).toLocal();
    _status = log?.status ?? SessionStatus.finished;
    final seconds = log?.completedSeconds ?? 25 * 60;
    _initialMinutesText = seconds % 60 == 0
        ? '${seconds ~/ 60}'
        : (seconds / 60).toStringAsFixed(1);
    _minutesController = TextEditingController(text: _initialMinutesText);
    _noteController = TextEditingController(text: log?.note ?? '');
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String? _validateMinutes(String? value) {
    final minutes = double.tryParse(value?.trim() ?? '');
    if (minutes == null) return 'Enter the completed minutes.';
    if (minutes <= 0) return 'Completed time must be greater than zero.';
    if (minutes > 240) return 'Completed time cannot exceed four hours.';
    return null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _startedAt.isAfter(now) ? now : _startedAt,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (date == null) return;
    setState(() {
      _startedAt = DateTime(
        date.year,
        date.month,
        date.day,
        _startedAt.hour,
        _startedAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startedAt),
    );
    if (time == null) return;
    setState(() {
      _startedAt = DateTime(
        _startedAt.year,
        _startedAt.month,
        _startedAt.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_startedAt.isAfter(DateTime.now())) {
      showMessage(context, 'The start time cannot be in the future.');
      return;
    }
    final preset = widget.presets.firstWhere((p) => p.id == _presetId);
    final original = widget.log;
    final text = _minutesController.text.trim();
    final seconds = original != null && text == _initialMinutesText
        ? original.completedSeconds
        : (double.parse(text) * 60).round();
    final keepMood = original != null && original.presetId == preset.id;
    final log = SessionLog(
      id: original?.id,
      presetId: preset.id!,
      startedAt: _startedAt,
      completedSeconds: seconds,
      moodTagSnapshot: keepMood ? original.moodTagSnapshot : preset.moodTag,
      status: _status,
      source: original?.source ?? 'manual',
      note: _noteController.text.trim(),
    );
    setState(() => _saving = true);
    try {
      final repository = ref.read(sessionLogRepositoryProvider);
      if (_isEditing) {
        await repository.update(log);
      } else {
        await repository.create(log);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showMessage(context, 'Could not save the log. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit session log' : 'Add session log'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: _presetId,
                decoration: const InputDecoration(
                  labelText: 'Preset',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final preset in widget.presets)
                    if (preset.id != null)
                      DropdownMenuItem(
                        value: preset.id,
                        child: Text('${preset.label} (${preset.moodTag})'),
                      ),
                ],
                validator: (value) => value == null ? 'Choose a preset.' : null,
                onChanged: (value) => setState(() => _presetId = value),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text('Date: ${formatDate(_startedAt)}'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      'Time: ${TimeOfDay.fromDateTime(_startedAt).format(context)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minutesController,
                decoration: const InputDecoration(
                  labelText: 'Completed time (minutes)',
                  suffixText: 'min',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: _validateMinutes,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SessionStatus>(
                isExpanded: true,
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: SessionStatus.finished,
                    child: Text('Finished'),
                  ),
                  DropdownMenuItem(
                    value: SessionStatus.reset,
                    child: Text('Reset early'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _status = value ?? _status),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLength: 200,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving...' : 'Save log'),
                    ),
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
