# Session Scout

Session Scout is an explainable local helper that suggests a starting session duration. It is not a prediction of attention, a health claim, or a cloud-AI feature.

## Method

For a selected mood, Session Scout uses the three most recent valid finished sessions. It selects their median completed duration, converts seconds to minutes, and clamps the result to 10 through 60 minutes. Fewer than three matching cases returns no suggestion and the interface displays `Not enough history`. The user must explicitly apply the suggestion and can edit it afterward.

The comparison baseline is a fixed 25-minute suggestion. Both approaches are scored with mean absolute error (MAE): the average absolute difference between the suggested and actual session duration.

## Five-case held-out scenario evaluation

The following deterministic scenarios were kept outside the helper implementation. They are reproducible test cases, not observations from human participants. Each history column lists the three prior same-mood sessions used by Session Scout.

| Case | Prior sessions (min) | Actual (min) | Scout | Scout error | Baseline | Baseline error |
|---|---:|---:|---:|---:|---:|---:|
| 1 | 20, 25, 30 | 27 | 25 | 2 | 25 | 2 |
| 2 | 15, 20, 35 | 22 | 20 | 2 | 25 | 3 |
| 3 | 30, 35, 40 | 33 | 35 | 2 | 25 | 8 |
| 4 | 8, 9, 12 | 11 | 10 | 1 | 25 | 14 |
| 5 | 55, 65, 70 | 58 | 60 | 2 | 25 | 33 |

Sample size: 5 cases. Session Scout MAE: 1.8 minutes. Fixed 25-minute baseline MAE: 12.0 minutes.

The results confirm that the implementation follows the intended median and clamp rules on these cases. They do not establish effectiveness for real students. The scenarios are synthetic, the sample is small, mood labels may be inconsistent, and interrupted sessions can be outliers. A stronger evaluation would prospectively collect sessions from multiple users and report results on a pre-registered, untouched test set. All app processing remains local and offline.

## Required case types

These cases are automated in `test/session_scout_cases_test.dart` and run through the same `scoutForMood` function the app uses.

| Type | Input (same mood, newest last) | Expected output | Why it matters |
|---|---|---|---|
| Normal | 20, 25, 30 min | Suggests 25 min | Median of three recent finished sessions |
| No data | 20, 25 min | `Not enough history` (2 of 3) | Never guesses from too little data |
| No data (mood mismatch) | Three Calm sessions, Focused selected | `Not enough history` (0 of 3) | Moods never borrow each other's history |
| Invalid | 20, 25 min plus a 0-min log and a 40-min **reset** log | `Not enough history` (2 of 3) | Empty and interrupted sessions are excluded |
| Boundary | 8, 9, 12 min | Suggests 10 min | Clamped to the 10–60 minute range |
| Tie | 20, 20, 30 min | Suggests 20 min | Repeated values give one deterministic answer |
| Outlier | 25, 26, 120 min | Suggests 26 min | The median ignores one unusually long session (a mean would say 57) |
| Recency | 90, then 20, 25, 30 min | Suggests 25 min | Only the three most recent sessions count |
| **Counterexample** | 55, 60, 65 min, then the student actually does 25 min | Scout 60 (error 35) vs baseline 25 (error 0) | When habits change, recent history misleads and the fixed baseline wins |

## Revision from the proposal wireframe

The proposal wireframe showed Session Scout as a plain "Session Scout: 25 min" line on the dashboard. That gave no reason and no way to act on it. The implemented card shows the explanation, the sample count or "Not enough history", and an explicit **Apply** button. On the dashboard, Apply opens a *new* preset form pre-filled with the suggestion rather than changing an existing preset, so a saved preset is never altered without the user opening and saving it.

**Limitation:** the cases above are synthetic and few. They check that the rules behave as documented; they do not show that the suggestion helps real students.

## User control and offline evidence

- The suggestion is shown on a card with its explanation and "a starting point, not a prediction of your attention".
- It fills the duration only after the user taps **Apply**, and the value stays editable. It never starts a timer, changes a setting, or saves a record. Widget test: `Session Scout suggestion fills the form only after Apply`.
- The calculation is pure Dart in `lib/application/session_scout.dart` and `lib/presentation/state/ui_providers.dart`. It reads only local SQLite history and makes no network calls.
