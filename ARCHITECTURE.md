# Adaptive Focus Studio Architecture

## Structure

The project uses presentation, application, domain, data, and services layers. Presentation code depends on providers and domain contracts. Domain models and repository interfaces do not import Flutter or SQLite. Data implementations depend inward on those interfaces.

## Dependency direction

`presentation -> application -> domain <- data`

Providers are the composition root that constructs the database and binds repository interfaces to SQLite implementations.

Device-facing reminder and export operations stay in `services`. Reminder permission is requested only after an explicit user action; denial is a normal recoverable result.

## State and persistence

Riverpod exposes cross-screen dependencies. `SessionController` isolates start, pause, resume, finish, and reset rules so they can be tested without a real clock. SQLite stores both entities with restricted preset deletion. Dates use UTC ISO 8601 strings and durations use seconds. SharedPreferences stores lightweight settings.

## Tradeoffs

Explicit mapping was chosen over generated models because the project has two entities and five screen roles. The schema starts at version 1; future changes must increment the version and add a migration.
