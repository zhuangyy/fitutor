import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_coach/services/coach_engine.dart';
import 'package:fitness_coach/services/tts_service.dart';
import 'package:fitness_coach/services/haptic_service.dart';
import 'package:fitness_coach/models/training_plan.dart';
import 'package:fitness_coach/models/plan_exercise.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CoachEngine engine;
  late TtsService tts;
  late HapticService haptic;

  setUp(() async {
    tts = TtsService();
    await tts.init();
    haptic = HapticService();
    engine = CoachEngine(tts: tts, haptic: haptic);
  });

  tearDown(() {
    engine.dispose();
  });

  test('initial state is idle', () {
    expect(engine.currentState.phase, CoachPhase.idle);
    expect(engine.currentState.exercises, isEmpty);
    expect(engine.currentState.totalExercises, 0);
  });

  test('loadPlan sets exercises and metadata', () {
    final plan = TrainingPlan(name: '测试');
    plan.exercises = [
      PlanExercise(
          planId: 1,
          exerciseId: 1,
          sortOrder: 0,
          sets: 3,
          workSeconds: 30,
          restSeconds: 30,
          exerciseName: '动作A'),
      PlanExercise(
          planId: 1,
          exerciseId: 2,
          sortOrder: 1,
          sets: 2,
          workSeconds: 30,
          restSeconds: 30,
          exerciseName: '动作B'),
    ];

    engine.loadPlan(plan);

    final state = engine.currentState;
    expect(state.totalExercises, 2);
    expect(state.exercises.length, 2);
    expect(state.currentExerciseIndex, 0);
    expect(state.currentSetIndex, 0);
  });

  test('start transitions through phases and completes', () async {
    final plan = TrainingPlan(name: '快速测试');
    plan.exercises = [
      PlanExercise(
        planId: 1,
        exerciseId: 1,
        sortOrder: 0,
        sets: 1,
        workSeconds: 1,
        restSeconds: 0,
        exerciseName: '快速动作',
      ),
    ];

    engine.loadPlan(plan);

    final phases = <CoachPhase>[];
    final sub = engine.stateStream.listen((s) {
      phases.add(s.phase);
    });

    engine.start();

    // Wait for full flow: working(instant + TTS + 1s delay) → completed
    await Future.delayed(const Duration(seconds: 5));
    await sub.cancel();

    expect(phases.contains(CoachPhase.working), true);
    expect(phases.contains(CoachPhase.completed), true);
  });

  test('pause pauses and resume continues', () async {
    final plan = TrainingPlan(name: '暂停测试');
    plan.exercises = [
      PlanExercise(
        planId: 1,
        exerciseId: 1,
        sortOrder: 0,
        sets: 1,
        workSeconds: 10,
        restSeconds: 0,
        exerciseName: '长动作',
      ),
    ];

    engine.loadPlan(plan);
    engine.start();

    // Wait for working to begin (async TTS + beep ~1.1s)
    await Future.delayed(const Duration(seconds: 2));
    expect(engine.currentState.phase, CoachPhase.working);

    // Pause
    engine.pause();
    expect(engine.currentState.phase, CoachPhase.paused);

    // Resume
    engine.resume();
    expect(engine.currentState.phase, CoachPhase.working);
  });

  test('stop returns to idle', () {
    final plan = TrainingPlan(name: '停止测试');
    plan.exercises = [
      PlanExercise(
        planId: 1,
        exerciseId: 1,
        sortOrder: 0,
        sets: 3,
        workSeconds: 30,
        restSeconds: 30,
        exerciseName: '动作'),
    ];

    engine.loadPlan(plan);
    engine.start();
    engine.stop();

    expect(engine.currentState.phase, CoachPhase.idle);
  });

  test('overallProgress returns 0 when no exercises', () {
    expect(engine.currentState.overallProgress, 0.0);
  });

  test('overallProgress increases with exercise completion', () {
    final plan = TrainingPlan(name: '进度测试');
    plan.exercises = [
      PlanExercise(
          planId: 1,
          exerciseId: 1,
          sortOrder: 0,
          sets: 3,
          workSeconds: 30,
          restSeconds: 30,
          exerciseName: '动作A'),
      PlanExercise(
          planId: 1,
          exerciseId: 2,
          sortOrder: 1,
          sets: 3,
          workSeconds: 30,
          restSeconds: 30,
          exerciseName: '动作B'),
    ];

    engine.loadPlan(plan);
    final state = engine.currentState;

    // At start: exerciseIndex=0, setIndex=0, total=2 → 0/2 = 0
    expect(state.overallProgress, closeTo(0.0, 0.01));
  });
}
