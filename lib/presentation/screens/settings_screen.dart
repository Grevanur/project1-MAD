import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../application/settings_store.dart';
import '../../services/history_export_service.dart';
import '../state/ui_providers.dart';
import '../widgets/dialogs.dart';
import '../widgets/state_views.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loading = true;
  bool _loadFailed = false;
  bool _saving = false;
  bool _exporting = false;
  bool _savedOnce = false;
  int _defaultMinutes = 25;
  bool _reducedMotion = false;
  bool _reminders = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final store = await ref.read(settingsStoreProvider.future);
      final settings = store.load();
      if (!mounted) return;
      setState(() {
        _defaultMinutes = settings.defaultMinutes;
        _reducedMotion = settings.reducedMotion;
        _reminders = settings.remindersEnabled;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  void _changed(VoidCallback update) {
    setState(() {
      update();
      _savedOnce = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final store = await ref.read(settingsStoreProvider.future);
      await store.save(
        AppSettings(
          defaultMinutes: _defaultMinutes,
          reducedMotion: _reducedMotion,
          remindersEnabled: _reminders,
        ),
      );
      if (!mounted) return;
      refreshAppData(ref);
      setState(() => _savedOnce = true);
      showMessage(context, 'Settings saved on this device.');
    } catch (_) {
      if (mounted) showMessage(context, 'Could not save settings.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final logs = await ref.read(sessionLogRepositoryProvider).getAll();
      if (logs.isEmpty) {
        if (mounted) showMessage(context, 'There is no history to export yet.');
        return;
      }
      final file = await HistoryExportService().export(logs);
      if (mounted) {
        showMessage(
          context,
          'Exported ${logs.length} sessions to ${file.path}',
        );
      }
    } catch (_) {
      if (mounted) showMessage(context, 'Export failed. Nothing was written.');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Builder(
        builder: (context) {
          if (_loading) return const LoadingView(label: 'Loading settings');
          if (_loadFailed) {
            return ErrorView(
              message: 'Settings could not be loaded.',
              onRetry: _load,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Default session length',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text('$_defaultMinutes minutes for new presets'),
                      Slider(
                        value: _defaultMinutes.clamp(5, 120).toDouble(),
                        min: 5,
                        max: 120,
                        divisions: 23,
                        label: '$_defaultMinutes min',
                        semanticFormatterCallback: (value) =>
                            '${value.round()} minutes',
                        onChanged: (value) =>
                            _changed(() => _defaultMinutes = value.round()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.motion_photos_off_outlined),
                      title: const Text('Reduce motion'),
                      subtitle: const Text(
                        'Turns off timer and completion animations.',
                      ),
                      value: _reducedMotion,
                      onChanged: (value) =>
                          _changed(() => _reducedMotion = value),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_outlined),
                      title: const Text('Local reminder'),
                      subtitle: const Text(
                        'Allow an on-device reminder for a planned session.',
                      ),
                      value: _reminders,
                      onChanged: (value) => _changed(() => _reminders = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving...' : 'Save settings'),
              ),
              if (_savedOnce)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Saved locally',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('Export session history'),
                  subtitle: const Text('Saves a CSV file on this device.'),
                  trailing: _exporting
                      ? const SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _exporting ? null : _export,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
