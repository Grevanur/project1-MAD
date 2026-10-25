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
