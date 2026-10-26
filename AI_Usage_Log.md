# AI Development Assistance Log

This log records AI tools used while *building* the app. It is separate from `AI_FEATURE.md`, which documents Session Scout, the app's own on-device helper. No AI service runs inside the app.

## Swamireddy Ailuri

| Date | Tool | What it was used for | What I did to verify or change it |
|---|---|---|---|
| Oct 24, 2026 | Claude (Anthropic) | Reviewed our proposal and listed mismatches between the wireframes and the written plan | Compared the list with the proposal myself; used it to plan the screen work |
| Oct 24, 2026 | [Other AI chat tool, if used: name it] | First attempt at the Activity, History and Settings screens | Discarded: it failed `flutter analyze` and was replaced |
| Oct 24, 2026 | Claude (Anthropic) | Generated the five presentation screens, shared widgets, UI providers, widget tests and the integration flow test, built on Gowtham's existing repositories, `SessionController` and `SessionScout` | Ran `flutter analyze` (no issues) and `flutter test`; 4 tests first failed (duplicate floating-button hero tags), which I reported and fixed; then all 36 passed. Tested every flow manually on the Android emulator |
| Oct 26, 2026 | Claude (Anthropic) | Swipe-to-delete on History, text-scaling fix and test, Session Scout case tests, coverage summary script, README and AI_FEATURE.md updates | Ran analyze and tests on my machine; checked each document against the course requirements and our actual app |

**What I am responsible for:** I chose which suggestions to keep, ran all checks on my own machine, and can explain every screen: how state flows through Riverpod, why timer rules stay in `SessionController`, how deletes are confirmed, and how the tests work.

**Limits I noticed:** the AI could not run Flutter itself, so every result was only trusted after I ran it locally. At least one claim (the first "revision" description in AI_FEATURE.md) was inaccurate and was corrected before committing.

## Gowtham Revanur

| Date | Tool | What it was used for | What I did to verify or change it |
|---|---|---|---|
| [date] | [tool or "none"] | [what] | [how verified] |
