# Adaptive Focus Studio

Offline Flutter study-session application. The current foundation contains Gowtham Revanur's assigned architecture, local data, state, timer, Session Scout, background summary, settings, export, and tests. Presentation screens are the teammate-owned integration slice described in `TEAMMATE_HANDOFF.md`.

## Verify

```bash
flutter pub get
flutter analyze
flutter test --coverage
flutter run
```

## Foundation

- Riverpod dependency injection
- SQLite `FocusPreset` and `SessionLog` repositories
- restricted preset deletion while related logs exist
- SharedPreferences settings store
- session state machine with duplicate-finish protection
- explainable Session Scout median rule and baseline metric
- isolate-based history summary and CSV export
- twenty automated tests

See `OWNERSHIP.md` and `TEAMMATE_HANDOFF.md` for collaboration.
