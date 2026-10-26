# Adaptive Focus Studio

Adaptive Focus Studio is an offline Flutter app that helps a college student start a manageable study session, run it with a deliberate timer, and learn from their own history which session length works for them. Everything is stored on the device; there is no account, cloud database, or network feature.

**Target users:** college students who want a quick, private way to begin a short study session and review what they actually completed.

## Team roles

| Member | Responsibilities |
|---|---|
| Gowtham Revanur | Architecture, Riverpod state, SQLite repositories, dependency injection, session state machine, Session Scout and its evaluation, background summary, notifications, CSV export, unit/repository tests, coverage, release build |
| Swamireddy Ailuri | Five-screen user interface, wireframes, validated preset and session-log forms, navigation, accessibility (labels, text scaling, reduced motion, landscape), empty/loading/error states, swipe and long-press gestures, widget and integration tests, peer testing, user guide |

Ownership details: [`OWNERSHIP.md`](OWNERSHIP.md).

## Features implemented

- **Dashboard:** focus-preset cards, mood filter, average completed duration with its sample count, Session Scout suggestion card, add/edit/delete presets (deleting a preset that still has session logs is blocked with an explanation)
- **Create / edit preset:** label, mood tag (fixed list), duration as a number field plus a 1–120 minute slider, inline validation, Session Scout **Apply** that fills the duration only when tapped
- **Focus (activity):** start, pause, resume, finish, reset; animated progress ring; session receipt; a session can be finished only once; reduced-motion support
- **History and insights:** filter by status (all / finished / reset) and mood, average with sample count, add a manual log (date and time pickers), edit, delete with confirmation, swipe left to delete
- **Settings:** default session length, reduced motion, local reminder preference and scheduling, CSV export of session history
- **Session Scout:** explainable, on-device duration suggestion (median of the three most recent finished sessions for a mood, clamped to 10–60 minutes) compared against a fixed 25-minute baseline. See [`AI_FEATURE.md`](AI_FEATURE.md).
- Responsive layout: bottom navigation in portrait, navigation rail in landscape and on wide screens
- Loading, empty, and error states on every screen; every gesture has a labeled button alternative

## Setup

**Requirements:** Flutter 3.44 (stable) with its bundled Dart SDK, Android Studio with an Android emulator or an Android phone with USB debugging.

```bash
git clone https://github.com/Grevanur/project1-MAD.git
cd project1-MAD
flutter pub get
flutter analyze
flutter test
flutter run
```

Other useful commands:

```bash
flutter test --coverage                     # unit + widget tests with coverage
dart run tool/coverage_summary.dart         # writes docs/COVERAGE.md
flutter test integration_test/app_flow_test.dart -d <android-device-id>
flutter build apk --release
```

The release APK is generated at `build/app/outputs/flutter-apk/app-release.apk`.

## User guide

1. **Create a preset.** On **Home**, tap **Add preset**. Enter a label (for example "Deep Work"), choose a mood, and set the duration with the number field or slider. Tap **Save preset**. Errors appear under any field that needs fixing.
2. **Start a session.** Tap **Start** on a preset card, or open the **Focus** tab and pick a preset. Tap **Start**. Use **Pause** / **Resume** as needed.
3. **Finish or reset.** Tap **Finish** to save what you completed; a receipt shows planned versus completed time. **Reset** stops early and saves the partial session as "reset".
4. **Review history.** Open **History** to see every session. Filter by status or mood; the card at the top shows the average and how many sessions it is based on. Tap a row or the pencil to edit it. Delete with the trash icon or by swiping the row left; both ask for confirmation. Use **Add log** to record a session you did without the timer.
5. **Use Session Scout.** On Home, choose a mood chip. After three finished sessions with that mood, Session Scout suggests a starting length and explains why. Nothing changes until you tap **Apply**, and you can still edit the value. With fewer than three sessions it says "Not enough history".
6. **Settings.** Set the default length for new presets, turn on **Reduce motion**, enable a local reminder, and tap **Save settings**. **Export session history** writes a CSV file on the device.
7. **Edit or delete a preset.** Use the pencil or trash icon on a card, or long-press a card to edit. A preset with session logs cannot be deleted until those logs are deleted or reassigned in History.

## Tech and data

- **Flutter** 3.44 stable, **Dart** 3.13 (bundled), Material 3
- **Packages:** `flutter_riverpod` 3.4.3 (state and dependency injection), `sqflite` 2.4.5 and `path` 1.9.1 (SQLite), `shared_preferences` 2.5.6 (settings), `path_provider` 2.1.6 (export location), `flutter_local_notifications` 22.3.2 and `timezone` 0.11.2 (local reminders)
- **Dev packages:** `flutter_test`, `integration_test`, `flutter_lints` 6.0.0, `sqflite_common_ffi` 2.4.5 (repository tests)
- **Architecture:** presentation → application → domain ← data, with services for device features. See [`ARCHITECTURE.md`](ARCHITECTURE.md).

### Database schema (SQLite, version 1)

```sql
CREATE TABLE focus_presets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  label TEXT NOT NULL CHECK(length(trim(label)) > 0),
  mood_tag TEXT NOT NULL,
  planned_seconds INTEGER NOT NULL CHECK(planned_seconds > 0)
);

CREATE TABLE session_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  preset_id INTEGER NOT NULL,
  started_at TEXT NOT NULL,             -- UTC ISO 8601
  completed_seconds INTEGER NOT NULL CHECK(completed_seconds >= 0),
  mood_tag_snapshot TEXT NOT NULL,
  status TEXT NOT NULL CHECK(status IN ('finished', 'reset')),
  source TEXT NOT NULL,                 -- 'timer' or 'manual'
  note TEXT NOT NULL DEFAULT '',
  FOREIGN KEY(preset_id) REFERENCES focus_presets(id) ON DELETE RESTRICT
);
```

Indexes exist on `session_logs(preset_id)` and `session_logs(mood_tag_snapshot)`. Foreign keys are enabled, so deleting a preset that still has logs is refused (parent-delete policy: **restrict**). Durations are stored in seconds and shown in minutes.

**SharedPreferences keys:** `default_minutes`, `reduced_motion`, `reminders_enabled`.

## Testing

- Unit and repository tests: domain validation, SQLite CRUD, session state machine, Session Scout rules, five helper case types, baseline comparison
- Widget tests: every screen, form validation, single-finish protection, filters, confirmations, swipe-to-delete, settings persistence, landscape layout, 1.5× text scaling
- Integration test: create a preset → run and finish a session → see it in History
- Coverage report: [`docs/COVERAGE.md`](docs/COVERAGE.md)

## Project management

- **ClickUp board:** https://app.clickup.com/90141771007/v/li/901422308229
- **Kanban evidence:** [`Kanban_Contribution_Evidence.pdf`](Kanban_Contribution_Evidence.pdf) (repository root)
- **Peer test and design revision:** [`docs/PEER_TEST.md`](docs/PEER_TEST.md)
- **AI development assistance:** [`AI_Usage_Log.md`](AI_Usage_Log.md)

## Known issues

- A running session lives in memory. If Android closes the app mid-session, the unfinished session is lost; finished and reset sessions are already saved.
- The CSV export is written to the app's private documents folder, which is not visible in every Android file manager.
- Reminders need notification permission; Android may deliver them a little late because they use inexact scheduling to save battery.
- Session Scout needs three finished sessions for a mood before it can suggest anything, and it cannot detect a change in study habits (see the counterexample in `AI_FEATURE.md`).

## Future enhancements

- Keep an in-progress session across app restarts
- Manual dark-mode switch (the app currently follows the system theme)
- Charts of completed time per week
- Import history from CSV
- Let users rename or add their own mood tags

## License

MIT License. See [`LICENSE`](LICENSE).

Repository: https://github.com/Grevanur/project1-MAD
