import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fitness_coach/services/coach_engine.dart';
import 'package:fitness_coach/services/tts_service.dart';
import 'package:fitness_coach/services/haptic_service.dart';
import 'package:fitness_coach/models/training_plan.dart';
import 'package:fitness_coach/database/session_dao.dart';
import 'package:fitness_coach/models/workout_session.dart';

class WorkoutProvider extends ChangeNotifier {
  late final CoachEngine _engine;
  final SessionDao _sessionDao = SessionDao();
  CoachState _coachState = const CoachState();
  StreamSubscription<CoachState>? _sub;
  DateTime? _workoutStartedAt;
  String? _planName;

  WorkoutProvider({required TtsService tts, required HapticService haptic}) {
    _engine = CoachEngine(tts: tts, haptic: haptic);
    _sub = _engine.stateStream.listen((state) {
      _coachState = state;
      if (state.phase == CoachPhase.completed) {
        _saveSession();
      }
      notifyListeners();
    });
  }

  CoachState get coachState => _coachState;

  void loadPlan(TrainingPlan plan, {int intervalSeconds = 0}) {
    _planName = plan.name;
    _engine.reminderIntervalSeconds = intervalSeconds;
    _engine.loadPlan(plan);
    notifyListeners();
  }

  void startWorkout() {
    _workoutStartedAt = DateTime.now();
    _engine.start();
  }

  void pause() => _engine.pause();
  void resume() => _engine.resume();
  void skipRest() => _engine.skipRest();
  void stopWorkout() => _engine.stop();

  Future<void> _saveSession() async {
    if (_workoutStartedAt == null) return;
    final now = DateTime.now();
    final duration = now.difference(_workoutStartedAt!).inSeconds;

    final exercises = _coachState.exercises.map((e) {
      return CompletedExercise(
        exerciseName: e.exerciseName ?? '未知动作',
        plannedSets: e.sets,
        completedSets: e.sets,
      );
    }).toList();

    final session = WorkoutSession(
      planId: 0,
      planName: _planName ?? '',
      startedAt: _workoutStartedAt!.toIso8601String(),
      finishedAt: now.toIso8601String(),
      durationSec: duration,
      completedExercises: exercises,
    );

    await _sessionDao.insert(session);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _engine.dispose();
    super.dispose();
  }
}
