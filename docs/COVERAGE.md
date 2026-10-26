# Test Coverage Report

Generated 2026-10-26 with `flutter test --coverage` and `dart run tool/coverage_summary.dart`.

**Total line coverage: 85.3%** (1044 of 1224 lines in `lib/`).

| File | Lines hit | Coverage |
|---|---:|---:|
| `lib/application/providers.dart` | 7 / 12 | 58.3% |
| `lib/application/session_controller.dart` | 32 / 35 | 91.4% |
| `lib/application/session_scout.dart` | 14 / 15 | 93.3% |
| `lib/application/settings_store.dart` | 10 / 10 | 100.0% |
| `lib/data/app_database.dart` | 15 / 16 | 93.8% |
| `lib/data/sqlite_repositories.dart` | 28 / 50 | 56.0% |
| `lib/domain/focus_preset.dart` | 18 / 18 | 100.0% |
| `lib/domain/session_log.dart` | 10 / 19 | 52.6% |
| `lib/presentation/app.dart` | 34 / 35 | 97.1% |
| `lib/presentation/formatters.dart` | 24 / 24 | 100.0% |
| `lib/presentation/screens/activity_screen.dart` | 173 / 191 | 90.6% |
| `lib/presentation/screens/dashboard_screen.dart` | 97 / 104 | 93.3% |
| `lib/presentation/screens/history_screen.dart` | 118 / 127 | 92.9% |
| `lib/presentation/screens/preset_form_screen.dart` | 86 / 92 | 93.5% |
| `lib/presentation/screens/session_log_form_screen.dart` | 95 / 129 | 73.6% |
| `lib/presentation/screens/settings_screen.dart` | 127 / 152 | 83.6% |
| `lib/presentation/state/ui_providers.dart` | 35 / 35 | 100.0% |
| `lib/presentation/widgets/dialogs.dart` | 22 / 22 | 100.0% |
| `lib/presentation/widgets/preset_card.dart` | 27 / 27 | 100.0% |
| `lib/presentation/widgets/scout_card.dart` | 31 / 31 | 100.0% |
| `lib/presentation/widgets/session_receipt.dart` | 22 / 22 | 100.0% |
| `lib/presentation/widgets/state_views.dart` | 17 / 23 | 73.9% |
| `lib/services/history_export_service.dart` | 0 / 16 | 0.0% |
| `lib/services/reminder_service.dart` | 2 / 19 | 10.5% |

Platform services (notifications, file export) are covered through fakes in widget tests and on-device checks; see README.
