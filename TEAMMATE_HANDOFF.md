# Swamireddy UI Handoff

Build the five required screen roles on the tested local foundation. Do not create a second database, duplicate domain models, or place timer rules inside widgets.

## Start

```bash
git clone https://github.com/Grevanur/project1-MAD.git
cd project1-MAD
git switch main
git pull origin main
git switch -c feature/swamireddy-ui
flutter pub get
flutter analyze
flutter test
```

Create presentation screens for Dashboard, Create or Edit Preset, Activity, History and Insights, and Settings under `lib/presentation/screens`. Add reusable widgets and dialogs under their own presentation folders. Replace the temporary `FoundationScreen` in `lib/presentation/app.dart` with navigation.

## Acceptance checklist

- Dashboard lists presets, filters by mood, shows average with sample count, and has Add Preset.
- Preset form validates label, mood, and positive duration with visible units.
- Activity provides accessible start, pause, resume, finish, and reset controls.
- Finish creates only one receipt even when tapped repeatedly.
- History lists, filters, edits, and deletes logs with confirmation.
- Settings persists default duration, reduced motion, and reminder preference.
- Every screen has loading, empty, and error behavior.
- Gestures have accessible button alternatives.
- Layout works in portrait and landscape.
- Add widget tests and an integration flow from preset creation through finishing.

## Commit and push

Commit work you personally implement and verify in small functional changes. Then run:

```bash
flutter analyze
flutter test --coverage
git push -u origin feature/swamireddy-ui
```

Open a pull request from `feature/swamireddy-ui` into `main`, list completed acceptance items and test results, and request Gowtham as reviewer. Do not push directly to `main`.

If a domain or application contract is insufficient, make a small explained change or request it in review. Do not replace repository storage with widget-owned storage.
