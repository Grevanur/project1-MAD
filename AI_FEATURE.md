# Session Scout

Session Scout provides an explainable starting-duration suggestion, not a prediction of attention or a health claim.

It uses the three most recent valid finished sessions matching the selected mood. It selects the median completed duration, converts seconds to minutes, and clamps the result to 10 through 60 minutes. Fewer than three cases returns no suggestion. The interface must say `Not enough history`. The user must explicitly apply and may edit the value.

The baseline is a fixed 25 minutes. `meanAbsoluteError` compares predicted and actual minutes over identical held-out cases. The final report must use at least five held-out cases, show case-level errors, both average errors, sample size, and limitations.

Three cases remain a small sample. Mood labels can be inconsistent and interrupted sessions can be outliers. All processing remains local and offline.
