import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_coach/models/training_plan.dart';
import 'package:fitness_coach/models/plan_exercise.dart';

void main() {
  group('TrainingPlan', () {
    test('fromMap creates plan without exercises', () {
      final map = {
        'id': 1,
        'name': '推胸日',
        'description': '专注胸部训练',
      };
      final plan = TrainingPlan.fromMap(map);
      expect(plan.name, '推胸日');
      expect(plan.exercises, isEmpty);
    });

    test('estimatedDurationText', () {
      final plan = TrainingPlan(name: '测试');
      plan.exercises = [
        PlanExercise(
            planId: 1,
            exerciseId: 1,
            sortOrder: 0,
            sets: 3,
            workSeconds: 45,
            restSeconds: 60),
        PlanExercise(
            planId: 1,
            exerciseId: 2,
            sortOrder: 1,
            sets: 3,
            workSeconds: 45,
            restSeconds: 60),
      ];
      // 2 × 3 × (45+60) = 2 × 315 = 630s = 10.5min → "约10分钟"
      expect(plan.estimatedDurationText, '约10分钟');
    });

    test('exerciseCount', () {
      final plan = TrainingPlan(name: '测试');
      plan.exercises = [
        PlanExercise(
            planId: 1,
            exerciseId: 1,
            sortOrder: 0,
            sets: 3,
            workSeconds: 30,
            restSeconds: 30),
      ];
      expect(plan.exerciseCount, 1);
    });
  });
}
