import 'dart:async';
import 'package:fitness_coach/models/training_plan.dart';
import 'package:fitness_coach/models/plan_exercise.dart';
import 'package:fitness_coach/services/tts_service.dart';
import 'package:fitness_coach/services/haptic_service.dart';

enum CoachPhase {
  idle,
  announcing,
  working,
  paused,
  resting,
  transitioning,
  completed,
}

class CoachState {
  final CoachPhase phase;
  final int currentExerciseIndex;
  final int currentSetIndex;
  final int totalExercises;
  final int totalSetsForCurrentExercise;
  final int remainingSeconds;
  final PlanExercise? currentExercise;
  final List<PlanExercise> exercises;
  final DateTime? startedAt;

  const CoachState({
    this.phase = CoachPhase.idle,
    this.currentExerciseIndex = 0,
    this.currentSetIndex = 0,
    this.totalExercises = 0,
    this.totalSetsForCurrentExercise = 0,
    this.remainingSeconds = 0,
    this.currentExercise,
    this.exercises = const [],
    this.startedAt,
  });

  CoachState copyWith({
    CoachPhase? phase,
    int? currentExerciseIndex,
    int? currentSetIndex,
    int? totalExercises,
    int? totalSetsForCurrentExercise,
    int? remainingSeconds,
    PlanExercise? currentExercise,
    List<PlanExercise>? exercises,
    DateTime? startedAt,
  }) {
    return CoachState(
      phase: phase ?? this.phase,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
      totalExercises: totalExercises ?? this.totalExercises,
      totalSetsForCurrentExercise:
          totalSetsForCurrentExercise ?? this.totalSetsForCurrentExercise,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      currentExercise: currentExercise ?? this.currentExercise,
      exercises: exercises ?? this.exercises,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  /// 整体进度 0.0 - 1.0
  double get overallProgress {
    if (totalExercises == 0) return 0;
    final exerciseProgress = currentExerciseIndex / totalExercises;
    final totalSets = currentExercise?.sets ?? 1;
    if (totalSets == 0) return exerciseProgress;
    final setProgress =
        (currentSetIndex / totalSets) / totalExercises;
    return exerciseProgress + setProgress;
  }
}

class CoachEngine {
  final TtsService _tts;
  final HapticService _haptic;

  final StreamController<CoachState> _stateController =
      StreamController<CoachState>.broadcast();

  Stream<CoachState> get stateStream => _stateController.stream;

  CoachState _state = const CoachState();
  CoachState get currentState => _state;

  Timer? _timer;
  DateTime? _timerBase;
  CoachPhase _phaseBeforePause = CoachPhase.working;

  CoachEngine({required TtsService tts, required HapticService haptic})
      : _tts = tts,
        _haptic = haptic;

  void loadPlan(TrainingPlan plan) {
    _emit(_state.copyWith(
      phase: CoachPhase.idle,
      exercises: List.from(plan.exercises),
      totalExercises: plan.exerciseCount,
      currentExerciseIndex: 0,
      currentSetIndex: 0,
      currentExercise: plan.exercises.isNotEmpty ? plan.exercises.first : null,
      remainingSeconds: 0,
    ));
  }

  void start() {
    if (_state.exercises.isEmpty) return;
    _enterAnnouncing();
  }

  void pause() {
    if (_state.phase != CoachPhase.working &&
        _state.phase != CoachPhase.resting) return;
    _timer?.cancel();
    _phaseBeforePause = _state.phase;
    _emitState(CoachPhase.paused);
    _tts.speak('暂停中');
  }

  void resume() {
    if (_state.phase != CoachPhase.paused) return;
    final remaining = _state.remainingSeconds;
    final phase = _phaseBeforePause;
    _emitState(phase, remaining: remaining);
    _startTimer(remaining, () => _onTimerComplete());
  }

  void skipRest() {
    if (_state.phase != CoachPhase.resting) return;
    _timer?.cancel();
    _onRestComplete();
  }

  void stop() {
    _timer?.cancel();
    _emit(const CoachState(phase: CoachPhase.idle));
  }

  void dispose() {
    _timer?.cancel();
    _stateController.close();
  }

  // ─── 状态转换 ───

  void _emitState(CoachPhase phase, {int remaining = 0}) {
    _emit(_state.copyWith(phase: phase, remainingSeconds: remaining));
  }

  void _emit(CoachState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  void _startTimer(int seconds, void Function() onDone) {
    _timerBase = DateTime.now();
    _emit(_state.copyWith(phase: _state.phase, remainingSeconds: seconds));

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsed = DateTime.now().difference(_timerBase!).inSeconds;
      final remaining = seconds - elapsed;

      if (remaining <= 0) {
        timer.cancel();
        onDone();
        return;
      }

      _emit(_state.copyWith(
          phase: _state.phase, remainingSeconds: remaining));

      // 最后3秒：震动
      if (remaining <= 3) {
        _haptic.countdownBuzz(remaining);
        // 最后1秒不重复播语音（避免叠音）
        if (remaining > 1) {
          _tts.speak('$remaining');
        } else if (remaining == 1) {
          _tts.speak('开始');
        }
      }
    });
  }

  void _enterAnnouncing() {
    final exercise = _state.exercises[_state.currentExerciseIndex];
    _emit(_state.copyWith(
      phase: CoachPhase.announcing,
      currentExercise: exercise,
      currentSetIndex: 0,
      totalSetsForCurrentExercise: exercise.sets,
      remainingSeconds: 3,
    ));
    _tts.speak(_announcementText(exercise));
    _startTimer(3, () => _beginWorking());
  }

  void _beginWorking() {
    final exercise = _state.currentExercise!;
    final workTime = exercise.workSeconds;
    _emitState(CoachPhase.working, remaining: workTime);
    _startTimer(workTime, () => _onWorkComplete());
  }

  void _onWorkComplete() {
    final exercise = _state.currentExercise!;
    final newSetIndex = _state.currentSetIndex + 1;

    if (newSetIndex >= exercise.sets) {
      _tts.speak('${exercise.exerciseName ?? '动作'}完成');
      _enterTransitioning();
    } else {
      _emit(_state.copyWith(currentSetIndex: newSetIndex));
      _emitState(CoachPhase.resting, remaining: exercise.restSeconds);
      _startTimer(exercise.restSeconds, () => _onRestComplete());
    }
  }

  void _onRestComplete() {
    _emitState(CoachPhase.working,
        remaining: _state.currentExercise!.workSeconds);
    _startTimer(_state.currentExercise!.workSeconds, () => _onWorkComplete());
  }

  void _enterTransitioning() {
    final newExIndex = _state.currentExerciseIndex + 1;
    if (newExIndex >= _state.totalExercises) {
      _emitState(CoachPhase.completed);
      _haptic.heavy();
      _tts.speak('太棒了，训练完成！');
      return;
    }

    final nextExercise = _state.exercises[newExIndex];
    _emit(_state.copyWith(
      phase: CoachPhase.transitioning,
      currentExerciseIndex: newExIndex,
      currentSetIndex: 0,
      currentExercise: nextExercise,
      remainingSeconds: 2,
    ));
    _tts.speak('下一动作：${nextExercise.exerciseName ?? ''}');

    Future.delayed(const Duration(seconds: 2), () {
      if (_state.phase == CoachPhase.transitioning) {
        _enterAnnouncing();
      }
    });
  }

  void _onTimerComplete() {
    switch (_state.phase) {
      case CoachPhase.announcing:
        _beginWorking();
        break;
      case CoachPhase.working:
        _onWorkComplete();
        break;
      case CoachPhase.resting:
        _onRestComplete();
        break;
      default:
        break;
    }
  }

  String _announcementText(PlanExercise exercise) {
    final name = exercise.exerciseName ?? '动作';
    final sets = exercise.sets;
    final workSec = exercise.workSeconds;
    if (exercise.reps != null) {
      return '$name，$sets组，每组${exercise.reps}次，训练${workSec}秒';
    }
    return '$name，$sets组，每组${workSec}秒';
  }
}
