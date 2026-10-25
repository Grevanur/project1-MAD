import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/focus_preset.dart';
import '../state/ui_providers.dart';
import '../widgets/dialogs.dart';
import '../widgets/scout_card.dart';

/// Create or edit a preset. Pops `true` after a successful save.
class PresetFormScreen extends ConsumerStatefulWidget {
  const PresetFormScreen({
    super.key,
    this.preset,
    this.initialMinutes = 25,
    this.initialMood,
  });

  final FocusPreset? preset;
  final int initialMinutes;
  final String? initialMood;

  @override
  ConsumerState<PresetFormScreen> createState() => _PresetFormScreenState();
}

class _PresetFormScreenState extends ConsumerState<PresetFormScreen> {
  static const int _sliderMax = 120;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _minutesController;
  String? _mood;
  late int _minutes;
  bool _saving = false;

  bool get _isEditing => widget.preset != null;

  @override
  void initState() {
    super.initState();
    final preset = widget.preset;
    _labelController = TextEditingController(text: preset?.label ?? '');
    _mood = preset?.moodTag ?? widget.initialMood;
    _minutes = preset != null
        ? (preset.plannedSeconds / 60).round()
        : widget.initialMinutes;
    _minutesController = TextEditingController(text: '$_minutes');
  }

  @override
  void dispose() {
    _labelController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  void _setMinutes(int minutes) {
    setState(() {
      _minutes = minutes;
      _minutesController.text = '$minutes';
    });
  }

  String? _validateMinutes(String? value) {
    final minutes = int.tryParse(value?.trim() ?? '');
    if (minutes == null) return 'Enter the duration in whole minutes.';
    return FocusPreset.validateDuration(minutes * 60);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final minutes = int.parse(_minutesController.text.trim());
    final preset = FocusPreset(
      id: widget.preset?.id,
      label: _labelController.text.trim(),
      moodTag: _mood!,
      plannedSeconds: minutes * 60,
    );
    setState(() => _saving = true);
    try {
      final repository = ref.read(presetRepositoryProvider);
      if (_isEditing) {
        await repository.update(preset);
      } else {
        await repository.create(preset);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showMessage(context, 'Could not save the preset. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final moods = {...kMoodOptions, ?_mood}.toList();
    final logs = ref.watch(sessionLogsProvider).value;
    final scout = (_mood == null || logs == null)
        ? null
        : scoutForMood(ref.read(sessionScoutProvider), logs, _mood!);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit preset' : 'New preset')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  hintText: 'For example, Deep Work',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                maxLength: 60,
                validator: (value) => FocusPreset.validateLabel(value ?? ''),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _mood,
                decoration: const InputDecoration(
                  labelText: 'Mood tag',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final mood in moods)
                    DropdownMenuItem(value: mood, child: Text(mood)),
                ],
                validator: (value) =>
                    value == null ? 'Choose a mood tag.' : null,
                onChanged: (value) => setState(() => _mood = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minutesController,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  suffixText: 'min',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _validateMinutes,
                onChanged: (value) {
                  final minutes = int.tryParse(value);
                  if (minutes != null) setState(() => _minutes = minutes);
                },
              ),
              Slider(
                value: _minutes.clamp(1, _sliderMax).toDouble(),
                min: 1,
                max: _sliderMax.toDouble(),
                divisions: _sliderMax - 1,
                label: '$_minutes min',
                semanticFormatterCallback: (value) =>
                    '${value.round()} minutes',
                onChanged: (value) => _setMinutes(value.round()),
              ),
              Text(
                'Planned length: $_minutes minutes',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ScoutCard(mood: _mood, result: scout, onApply: _setMinutes),
              const SizedBox(height: 24),
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
                      child: Text(_saving ? 'Saving...' : 'Save preset'),
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
