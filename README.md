# Adaptive Focus Studio

Adaptive Focus Studio is an offline Flutter study-session application. Users can create focus presets, run timed sessions, review and edit session history, filter results, export history as CSV, configure local preferences, and optionally schedule local reminders. Session Scout provides an explainable, on-device duration suggestion from recent sessions with the same mood tag.

## Main features

- Dashboard with preset CRUD, mood filtering, averages, and Session Scout
- Validated preset creation and editing
- Focus timer with start, pause, resume, finish, reset, and duplicate-finish protection
- History filtering, manual log entry, editing, deletion, and summary statistics
- SharedPreferences settings, reduced-motion support, and responsive navigation
- SQLite persistence for related `FocusPreset` and `SessionLog` entities
- CSV file export and opt-in local reminders
- Riverpod dependency injection and separated presentation, application, domain, data, and service layers
- Unit, repository, widget, and Android integration tests

## Verify

```bash
flutter pub get
flutter analyze
flutter test --coverage
flutter test integration_test/app_flow_test.dart -d <android-device-id>
flutter build apk --release
```

The release APK is generated at `build/app/outputs/flutter-apk/app-release.apk`.

## Documentation

- `ARCHITECTURE.md` explains dependency direction, persistence, state, and tradeoffs.
- `AI_FEATURE.md` documents Session Scout, its baseline comparison, evaluation, and limitations.
- `OWNERSHIP.md` records team responsibilities.
- `TEAMMATE_HANDOFF.md` preserves the original UI integration handoff and acceptance checklist.

Repository: https://github.com/Grevanur/project1-MAD
