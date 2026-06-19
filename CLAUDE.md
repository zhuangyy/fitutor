# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Fitness Coach (跟我练) — a Flutter mobile app (Android + iOS) that provides a virtual voice coach to guide users through gym workouts. 100% offline, no backend, no accounts.

## Commands

All commands run from `fitness_coach/`. The repo root contains Reasonix AI agent config (`.reasonix/`, `reasonix.toml`) — not part of the Flutter build.

```bash
# Run the app (device/emulator required)
flutter run

# Run all tests (requires proxy — see Proxy section below)
flutter test

# Run a single test file
flutter test test/models/exercise_test.dart

# Run tests with a name filter
flutter test --plain-name "fromMap"

# Static analysis / lint
flutter analyze

# Build APK
flutter build apk

# Build iOS
flutter build ios
```

### Proxy Setup

The `sqlite3` Dart package downloads a pre-compiled native library on first `flutter test` run, and Gradle downloads dependencies on first build. Both need a SOCKS5 proxy in this environment:

```bash
# For flutter test
ALL_PROXY=socks5://127.0.0.1:7890 HTTPS_PROXY=socks5://127.0.0.1:7890 HTTP_PROXY=socks5://127.0.0.1:7890 flutter test

# For flutter build apk (Gradle proxy is configured in android/gradle.properties)
ALL_PROXY=socks5://127.0.0.1:7890 HTTPS_PROXY=socks5://127.0.0.1:7890 flutter build apk
```

Gradle SOCKS5 proxy is pre-configured in `android/gradle.properties` via `systemProp.socksProxyHost/Port`.

## Architecture

```
UI (pages/widgets) → State (Provider) → Services → Data (sqflite DAOs)
```

### State Management

`provider` package. Three `ChangeNotifier` providers registered in `app.dart` via `MultiProvider`:

- **`PlanProvider`** — CRUD for training plans and their exercises. Owns `PlanDao`. Supports drag-to-reorder.
- **`WorkoutProvider`** — Wraps `CoachEngine`, listens to its state stream, persists completed sessions via `SessionDao`.
- **`SettingsProvider`** — TTS mute, haptic toggle, daily reminder scheduling. Wires to `TtsService`, `HapticService`, `NotificationService`.

### CoachEngine (the core)

`lib/services/coach_engine.dart` — state machine driving the workout:

```
IDLE → ANNOUNCING(3s) → WORKING(countdown) → RESTING(rest countdown)
                          ↕ PAUSED              ↕ PAUSED
RESTING → next set → WORKING
        → all sets done → TRANSITIONING(2s) → next exercise → ANNOUNCING
                                           → no more → COMPLETED
```

- Exposes `Stream<CoachState>` for the UI.
- **Timer precision:** `DateTime.now()` delta from `_timerBase` (not `Timer` ticks) to survive iOS background suspension.
- **TTS:** Serial speech via `TtsService.speak()` — no concurrent speech. Countdown "3, 2, 1" with "开始" at the final second.
- **Haptics:** Light → medium → heavy buzz on last 3 seconds of each countdown, final heavy buzz on completion.
- **Beep:** `lib/utils/beep.dart` plays a system beep sound for mid-workout cues.
- **Mid-workout reminders:** TTS announces approaching next exercise ("下一组是...") and rest-time remaining at halfway.

### Services

| Service | Purpose |
|---|---|
| `CoachEngine` | Workout state machine (see above) |
| `TtsService` | Flutter TTS wrapper, serial speech queue |
| `HapticService` | Haptic feedback wrapper |
| `NotificationService` | Local push notifications for daily training reminders. Uses `flutter_local_notifications` with `zonedSchedule`, repeating daily at user-set time |

### Database

SQLite via `sqflite`. Singleton `DatabaseHelper` (lazy init). Four tables:

| Table | Purpose |
|---|---|
| `exercises` | Exercise library — 49 presets seeded on first launch + user custom |
| `training_plans` | Named workout plans |
| `plan_exercises` | Join table: plan ↔ exercise with sort_order, sets, reps, work_seconds, rest_seconds |
| `workout_sessions` | Completed workout records with JSON snapshot of exercise completion |

DAOs (`ExerciseDao`, `PlanDao`, `SessionDao`) each hold a `DatabaseHelper()` reference. Pattern: `fromMap`/`toMap` on models, raw SQL for joins when needed.

### Exercise Model

Exercises have a `category` field: `'力量'` (strength, has reps) or `'计时'` (timed, no reps). `is_preset = 1` for built-in exercises loaded from `assets/data/preset_exercises.json` on first launch — these cannot be deleted, only user-created exercises can. Incremental sync updates presets across app versions.

### Navigation

Bottom `NavigationBar` with 3 tabs (IndexedStack): **计划** (plans), **历史** (history), **设置** (settings). All other pages are pushed via `Navigator.push` / `pushReplacement` with `MaterialPageRoute` — no named routes, no deep linking.

### Key Pages

| Page | Purpose |
|---|---|
| `HomePage` | Tab shell: plans list with drag-to-reorder, history, settings |
| `PlanEditPage` | Create/edit a training plan, reorder exercises, configure sets/reps/timers |
| `ExercisePicker` | Search/browse exercises by category with collapsible groups and search history |
| `ExerciseManagePage` | Full exercise library management: search, edit, add custom exercises, delete user exercises |
| `WorkoutPage` | Live workout view driven by CoachEngine stream |
| `WorkoutSummaryPage` | Post-workout completion summary |
| `HistoryDetailPage` | Drill-down into a past workout session |

### Key Design Decisions

- **100% offline** — no network dependencies, no user accounts.
- **Duration estimation:** `PlanExercise.estimatedDurationSeconds = sets × (workSeconds + restSeconds)`. `TrainingPlan` aggregates across all its exercises.
- **Workout snapshot:** Completed exercises stored as JSON in `exercises_json` at completion time, denormalized from the plan.
- **Exercise picker** defaults to categories collapsed; search history is persisted.
- **Drag-to-reorder** on both home page (plans) and plan edit page (exercises), using `ReordableListView`.

## Testing

Three categories in `test/`:

- **Model tests** (`test/models/`) — pure Dart unit tests for `fromMap`/`toMap`/computed getters. No setup.
- **Database tests** (`test/database/`) — use `sqflite_common_ffi` for transient SQLite. Each file calls `sqfliteFfiInit()` + `databaseFactory = databaseFactoryFfi` in `setUpAll`. `DatabaseHelper` has `resetDatabase()` between tests.
- **Service tests** (`test/services/`) — `coach_engine_test.dart` tests the state machine through start/pause/resume/stop/progress flows.
