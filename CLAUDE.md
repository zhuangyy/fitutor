# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Fitness Coach — a Flutter mobile app (Android + iOS) that provides a virtual coach to guide users through gym workouts. 100% offline, no backend, no accounts.

## Commands

```bash
# Run the app (device/emulator required)
cd fitness_coach && flutter run

# Run all tests
cd fitness_coach && flutter test

# Run a single test file
cd fitness_coach && flutter test test/models/exercise_test.dart

# Run tests with a name filter
cd fitness_coach && flutter test --plain-name "fromMap"

# Static analysis / lint
cd fitness_coach && flutter analyze

# Build APK
cd fitness_coach && flutter build apk

# Build iOS
cd fitness_coach && flutter build ios
```

All commands should be run from the `fitness_coach/` directory. The repo root contains Reasonix config (`.reasonix/`, `reasonix.toml`) and design docs (`docs/`) — neither is part of the Flutter build.

## Architecture

The app follows a 4-layer architecture:

```
UI (pages/widgets) → State (Provider) → Services → Data (sqflite DAOs)
```

### State Management

Uses `provider` package with three `ChangeNotifier` providers, all registered in `app.dart` via `MultiProvider`:

- **`PlanProvider`** — CRUD for training plans and their exercises. Owns `PlanDao`.
- **`WorkoutProvider`** — Wraps `CoachEngine`, listens to its state stream, and persists completed sessions via `SessionDao`.
- **`SettingsProvider`** — Toggles for TTS mute, haptic enable, and daily reminder scheduling.

### CoachEngine (the core)

`lib/services/coach_engine.dart` — a state machine that drives the workout experience:

```
IDLE → ANNOUNCING(3s) → WORKING(countdown) → RESTING(rest countdown)
                          ↕ PAUSED              ↕ PAUSED
RESTING → next set → WORKING
        → all sets done → TRANSITIONING(2s) → next exercise → ANNOUNCING
                                           → no more → COMPLETED
```

- Exposes `Stream<CoachState>` for the UI to react to.
- **Timer precision:** Uses `DateTime.now()` delta from `_timerBase`, not `Timer` tick count, to survive iOS background suspension.
- **TTS:** Speaks through `TtsService.speak()` — serial (no concurrent speech to avoid overlap). Speaks countdown "3, 2, 1" with "开始" at the final second.
- **Haptics:** Buzzes on last 3 seconds of each countdown (light → medium → heavy), plus a final heavy buzz on completion.

### Database

SQLite via `sqflite`. Singleton `DatabaseHelper` (lazy init). Four tables:

| Table | Purpose |
|---|---|
| `exercises` | Exercise library — ~30 presets seeded on first launch + user custom |
| `training_plans` | Named workout plans |
| `plan_exercises` | Join table: plan ↔ exercise with sort_order, sets, reps, work_seconds, rest_seconds |
| `workout_sessions` | Completed workout records with JSON snapshot of exercise completion |

DAO classes (`ExerciseDao`, `PlanDao`, `SessionDao`) each hold a reference to `DatabaseHelper()` and follow the same pattern: `fromMap`/`toMap` on models, raw SQL for joins where needed.

### Navigation

Bottom `NavigationBar` with 3 tabs (IndexedStack): **计划** (plans), **历史** (history), **设置** (settings). Workout and plan-edit pages are pushed on top of the tab shell via `Navigator.push`.

### Key Design Decisions

- **100% offline** — no network dependencies, no user accounts.
- **Duration estimation:** `PlanExercise.estimatedDurationSeconds = sets × (workSeconds + restSeconds)`. `TrainingPlan` aggregates across all its exercises.
- **Preset exercises** are loaded from `assets/data/preset_exercises.json` on first launch and flagged `is_preset = 1` in the DB.
- **Workout session snapshot:** Completed exercises stored as JSON in `exercises_json` column, denormalized from the plan at completion time.
- **No deep linking or named routes** — all navigation is `Navigator.push` / `pushReplacement` with `MaterialPageRoute`.

## Testing

Tests live in `fitness_coach/test/`. Two categories:

- **Model tests** (`test/models/`) — pure Dart unit tests for `fromMap`/`toMap`/computed getters. No setup needed.
- **Database tests** (`test/database/`) — use `sqflite_common_ffi` for in-memory SQLite. Each test file calls `sqfliteFfiInit()` in `setUpAll` and sets `databaseFactory = databaseFactoryFfi`.

The `DatabaseHelper` has a `resetDatabase()` method used between tests to start clean.
