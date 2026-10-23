import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    this.defaultMinutes = 25,
    this.reducedMotion = false,
    this.remindersEnabled = false,
  });
  final int defaultMinutes;
  final bool reducedMotion;
  final bool remindersEnabled;
}

class SettingsStore {
  SettingsStore(this._preferences);
  final SharedPreferences _preferences;
  AppSettings load() => AppSettings(
    defaultMinutes: _preferences.getInt('default_minutes') ?? 25,
    reducedMotion: _preferences.getBool('reduced_motion') ?? false,
    remindersEnabled: _preferences.getBool('reminders_enabled') ?? false,
  );
  Future<void> save(AppSettings value) async {
    await _preferences.setInt('default_minutes', value.defaultMinutes);
    await _preferences.setBool('reduced_motion', value.reducedMotion);
    await _preferences.setBool('reminders_enabled', value.remindersEnabled);
  }
}
