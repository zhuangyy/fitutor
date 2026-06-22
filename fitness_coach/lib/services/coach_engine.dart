import 'dart:async';
import 'package:fitness_coach/models/training_plan.dart';
import 'package:fitness_coach/models/plan_exercise.dart';
import 'package:fitness_coach/services/tts_service.dart';
import 'package:fitness_coach/services/haptic_service.dart';
import 'package:fitness_coach/utils/beep.dart';

enum CoachPhase {
  idle,
  announcing,
  working,
  paused,
  resting,              // 组间休息
  postExerciseResting,   // 动作完成后休息
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
  Future<void> Function()? _timerOnDone;
  CoachPhase _phaseBeforePause = CoachPhase.working;
  int _frozenRemaining = 0;

  /// 中途提醒间隔秒数，0 = 关闭
  int reminderIntervalSeconds = 0;

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
        _state.phase != CoachPhase.resting &&
        _state.phase != CoachPhase.postExerciseResting) return;
    _timer?.cancel();
    _phaseBeforePause = _state.phase;
    _frozenRemaining = _state.remainingSeconds;
    _emitState(CoachPhase.paused);
    _tts.speak('暂停中');
  }

  void resume() {
    if (_state.phase != CoachPhase.paused) return;
    final remaining = _frozenRemaining;
    final phase = _phaseBeforePause;
    _tts.speak('继续');
    _emitState(phase, remaining: remaining);
    _startTimer(remaining, _onTimerComplete);
  }

  void skipRest() {
    if (_state.phase != CoachPhase.resting &&
        _state.phase != CoachPhase.postExerciseResting) return;
    _timer?.cancel();
    _timerOnDone?.call();
  }

  void stop() {
    _timer?.cancel();
    _tts.speak('训练结束');
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

  void _startTimer(int seconds, Future<void> Function() onDone) {
    _timerOnDone = onDone;
    _timerBase = DateTime.now();
    _emit(_state.copyWith(phase: _state.phase, remainingSeconds: seconds));

    // 中途提醒间隔
    final interval = reminderIntervalSeconds;
    int lastAnnouncedRemaining = seconds; // 避免刚开始就播报

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

      // 中途间隔提醒：每隔 interval 秒播报剩余时间
      if (interval > 0 && remaining > 5 && remaining < lastAnnouncedRemaining) {
        if (remaining % interval == 0) {
          lastAnnouncedRemaining = remaining;
          final prefix =
              _state.phase == CoachPhase.resting ? '休息' : '';
          _tts.speak('${prefix}还剩余$remaining秒');
        }
      }

      // 最后5秒：震动 + 倒数
      if (remaining <= 5) {
        _haptic.countdownBuzz(remaining);
        _tts.stop();
        _tts.speak('$remaining');
      }
    });
  }

  Future<void> _beginWorking() async {
    final exercise = _state.currentExercise!;
    final workTime = exercise.workSeconds;
    // 先出倒计时界面，再播语音
    _emit(_state.copyWith(
      phase: CoachPhase.working,
      currentExercise: exercise,
      currentSetIndex: _state.currentSetIndex,
      totalSetsForCurrentExercise: exercise.sets,
      remainingSeconds: workTime,
    ));
    await _tts.speak(_announcementText(exercise));
    // 播报期间可能被 stop() 打断
    if (_state.phase != CoachPhase.working) return;
    await _tts.speak('开始');
    await Future.delayed(const Duration(seconds: 1));
    playBeep();
    _startTimer(workTime, _onWorkComplete);
  }

  // _enterAnnouncing 合并到 _beginWorking，先出界面再播语音
  Future<void> _enterAnnouncing() => _beginWorking();

  Future<void> _onWorkComplete() async {
    final exercise = _state.currentExercise!;
    final newSetIndex = _state.currentSetIndex + 1;

    if (newSetIndex >= exercise.sets) {
      final afterRest = exercise.afterRestSeconds;
      if (afterRest > 0) {
        _emitState(CoachPhase.postExerciseResting, remaining: afterRest);
        await _tts.speak('${exercise.exerciseName ?? '动作'}完成，休息${afterRest}秒');
        await Future.delayed(const Duration(seconds: 1));
        playBeep();
        _startTimer(afterRest, _onPostExerciseRestComplete);
      } else {
        await _tts.speak('${exercise.exerciseName ?? '动作'}完成');
        _enterTransitioning();
      }
    } else {
      _emit(_state.copyWith(currentSetIndex: newSetIndex));
      _emitState(CoachPhase.resting, remaining: exercise.restSeconds);
      await _tts.speak('休息${exercise.restSeconds}秒');
      await Future.delayed(const Duration(seconds: 1));
      playBeep();
      _startTimer(exercise.restSeconds, _onRestComplete);
    }
  }

  Future<void> _onRestComplete() async {
    final exercise = _state.currentExercise!;
    _emitState(CoachPhase.working, remaining: exercise.workSeconds);
    final setName =
        '${exercise.exerciseName ?? '动作'}，第${_state.currentSetIndex + 1}组';
    await _tts.speak(setName);
    await _tts.speak('开始');
    await Future.delayed(const Duration(seconds: 1));
    playBeep();
    _startTimer(exercise.workSeconds, _onWorkComplete);
  }

  Future<void> _onPostExerciseRestComplete() async {
    _enterTransitioning();
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

  Future<void> _onTimerComplete() async {
    switch (_state.phase) {
      case CoachPhase.announcing:
        await _beginWorking();
        break;
      case CoachPhase.working:
        await _onWorkComplete();
        break;
      case CoachPhase.resting:
        await _onRestComplete();
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
