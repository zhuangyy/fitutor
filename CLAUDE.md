# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

健身好搭子 (`fitness_coach`) — 一个健身动作编排和跟练 App（Android + iOS，application id `com.xzgg.fitutor`）。面向有一定健身基础、知道自己该练什么、会自己编排动作，但希望有个声音在耳边指导、伴随锻炼的使用者。7 个预置基础动作，其余由用户自行编排。100% 离线，无账号。

## Repository Layout

- Flutter project lives at the **repository root** (`lib/`, `android/`, `ios/`, `test/`).
- `docs/` — privacy policy + app screenshots (tracked); `docs/huawei/` — AppGallery listing materials, **kept local & git-ignored**.
- `.reasonix/`, `reasonix.toml` — Reasonix agent config, not part of the Flutter build.
- Signing keys (`android/key.properties`, `*.jks`, `*.keystore`) are git-ignored — never commit them.

## Commands

All commands run from the repository root.

```bash
# Run the app (device/emulator required)
flutter run

# Run all tests (requires proxy — see below)
flutter test

# Run a single test file
flutter test test/models/exercise_test.dart

# Static analysis / lint
flutter analyze

# Build APK (rename output with version)
flutter build apk && cp build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/fitutor-v$(grep version pubspec.yaml | head -1 | awk '{print $2}' | cut -d+ -f1).apk

# Build iOS (simulator)
flutter build ios --simulator
```

### Proxy Setup

The `sqlite3` Dart package downloads a pre-compiled native library, and Gradle downloads dependencies. Both need the SOCKS5 proxy:

```bash
# Prefix for flutter test / flutter run / flutter build
ALL_PROXY=socks5://127.0.0.1:7890 HTTPS_PROXY=socks5://127.0.0.1:7890 HTTP_PROXY=socks5://127.0.0.1:7890
```

Gradle SOCKS5 proxy is pre-configured in `android/gradle.properties`.

### Android Emulator

```bash
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
flutter emulators --launch Pixel7
flutter run -d emulator-5554
```

> Note: on this machine `adb shell input tap/swipe` does **not** reach the Flutter UI (keyevents do). Drive the UI through `integration_test` instead (see Testing).

### iOS Simulator

```bash
open -a Simulator
xcrun simctl boot <UUID>   # 12581C03-2D65-4931-9C3F-1C03636282EC for iPhone 17
flutter run -d <UUID>
```

## Architecture

```
UI (pages/widgets) → State (Provider) → Services → Data (sqflite DAOs)
```

> **Imports:** UI widgets come from `package:material_ui/material_ui.dart`. Since Flutter 3.50, `package:flutter/material.dart` is deprecated (Material moved to the standalone `material_ui` package); do not reintroduce it.

### CoachEngine (core state machine)

`lib/services/coach_engine.dart` — drives the workout with these phases:

```
IDLE → WORKING (countdown shown immediately, then TTS announcement)
  WORKING → timer ticks → last set? → postExerciseResting (if afterRestSeconds > 0) → TRANSITIONING(2s)
          → more sets?  → RESTING (between-set rest)
          ↕ PAUSED (working/resting/postExerciseResting all support pause)
COMPLETED
```

- `CoachPhase` enum: `idle`, `announcing`(unused), `working`, `paused`, `resting`, `postExerciseResting`, `transitioning`, `completed`
- **Countdown ring colors:** red (working), orange (between-set rest), green (post-exercise rest)
- **Timer:** `DateTime.now()` delta from `_timerBase`, not `Timer` ticks — survives iOS suspension
- **TTS:** Serial via `TtsService.speak()` with `awaitSpeakCompletion(true)` set once in `init()`
- **Beep:** Android `AudioTrack` 880Hz PCM, iOS `AudioServicesPlaySystemSound(1057)`
- **Background keep-alive:** iOS silent audio loop, Android foreground service

### Providers

- **`PlanProvider`** — CRUD for training plans, drag-to-reorder, exercise management
- **`WorkoutProvider`** — wraps CoachEngine, manages background service lifecycle, saves sessions (completed + interrupted), WidgetsBindingObserver for app lifecycle
- **`SettingsProvider`** — TTS mute, haptic, interval reminder (0-30s), tap-to-pause toggle

### Database

SQLite via `sqflite`. Singleton `DatabaseHelper` (db `fitness_coach.db`, version 4). Tables:

| Table | Key columns |
|---|---|
| `exercises` | name, category (力量/计时), muscle_group, is_preset, sort_order |
| `training_plans` | name, sort_order |
| `plan_exercises` | plan_id, exercise_id, sort_order, sets, reps, work_seconds, rest_seconds, **after_rest_seconds** |
| `workout_sessions` | plan_id, plan_name (snapshot), started_at, duration_sec, exercises_json, finished_at (null = interrupted) |

DAOs follow `fromMap`/`toMap` pattern. `PlanDao.replacePlanExercises` does DELETE + INSERT in a transaction.

### Navigation

4-tab `IndexedStack`: **计划** / **动作** / **历史** / **设置**. Other pages pushed via `Navigator.push`.

### Key Pages

| Page | Role |
|---|---|
| `HomePage` | Tab shell with plan list (drag-to-reorder cards) |
| `ExerciseManagePage` | Tab: search, add custom, edit/delete non-presets |
| `PlanEditPage` | Create/edit plan, reorder exercises, configure all params |
| `ExercisePicker` | Bottom sheet: browse/search by muscle group, set params, create custom inline |
| `WorkoutPage` | Countdown ring + exercise list (✓/●/○) + progress bar |
| `WorkoutSummaryPage` | Post-workout stats, auto-navigates |
| `HistoryPage` | Session list, refresh on tab switch after workout |
| `HistoryDetailPage` | Per-exercise completion detail (green check / orange warning) |
| `SettingsPage` | Voice, haptic, interval reminder, tap-to-pause, version (read via `package_info_plus`) |

## Testing

- **Model tests** (`test/models/`) — pure Dart, no setup
- **Database tests** (`test/database/`) — `sqflite_common_ffi` + `sqfliteFfiInit()` + `databaseFactoryFfi`
- **Service tests** (`test/services/coach_engine_test.dart`) — state transitions
- **Screenshot test** (`integration_test/android_screenshots_test.dart`) — starts the real app, builds its own sample data, drives the UI with the widget tester, prints `@@SHOT <name>` markers and pauses so an external script can `adb exec-out screencap`. `flutter test` uninstalls the app afterwards, so the test creates its data each run.

```bash
flutter test integration_test/android_screenshots_test.dart -d emulator-5554
```
