import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fitness_coach/services/coach_engine.dart';
import 'package:fitness_coach/services/tts_service.dart';
import 'package:fitness_coach/services/haptic_service.dart';
import 'package:fitness_coach/services/background_service_manager.dart';
import 'package:fitness_coach/models/training_plan.dart';
import 'package:fitness_coach/database/session_dao.dart';
import 'package:fitness_coach/models/workout_session.dart';

class WorkoutProvider extends ChangeNotifier with WidgetsBindingObserver {
  late final CoachEngine _engine;
  final SessionDao _sessionDao = SessionDao();
  final BackgroundServiceManager _bgService = BackgroundServiceManager();
  CoachState _coachState = const CoachState();
  StreamSubscription<CoachState>? _sub;
  DateTime? _workoutStartedAt;
  String? _planName;
  bool _wasBackgrounded = false;

  WorkoutProvider({required TtsService tts, required HapticService haptic}) {
    _engine = CoachEngine(tts: tts, haptic: haptic);
    _sub = _engine.stateStream.listen((state) {
      _coachState = state;
      if (state.phase == CoachPhase.completed) {
        _saveSession();
      }
      notifyListeners();
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasBackgrounded = true;
    } else if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      // 从后台恢复时刷新 UI，wall-clock delta 自动修正倒计时
      notifyListeners();
    }
  }

  CoachState get coachState => _coachState;

  /// 完成的训练次数，每次保存后递增，供 HistoryPage 判断是否需要刷新
  int _completedSessionCount = 0;
  int get completedSessionCount => _completedSessionCount;

  void loadPlan(TrainingPlan plan, {int intervalSeconds = 0}) {
    _planName = plan.name;
    _engine.reminderIntervalSeconds = intervalSeconds;
    _engine.loadPlan(plan);
    notifyListeners();
  }

  void startWorkout() {
    _workoutStartedAt = DateTime.now();
    _bgService.startWorkout();
    _engine.start();
  }

  void pause() => _engine.pause();
  void resume() => _engine.resume();
  void skipRest() => _engine.skipRest();

  void stopWorkout() {
    _engine.stop();
    _bgService.stopWorkout();
  }

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
    _completedSessionCount++;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _engine.dispose();
    super.dispose();
  }
}
