import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_coach/models/plan_exercise.dart';

void main() {
  group('PlanExercise', () {
    test('fromMap creates PlanExercise for strength exercise', () {
      final map = {
        'id': 10,
        'plan_id': 1,
        'exercise_id': 5,
        'sort_order': 0,
        'sets': 3,
        'reps': 10,
        'work_seconds': 45,
        'rest_seconds': 60,
        'notes': '注意控制节奏',
      };

      final pe = PlanExercise.fromMap(map);

      expect(pe.id, 10);
      expect(pe.planId, 1);
      expect(pe.exerciseId, 5);
      expect(pe.sets, 3);
      expect(pe.reps, 10);
      expect(pe.workSeconds, 45);
      expect(pe.restSeconds, 60);
      expect(pe.notes, '注意控制节奏');
    });

    test('toMap excludes null id', () {
      final pe = PlanExercise(
        planId: 1,
        exerciseId: 5,
        sortOrder: 0,
        sets: 3,
        reps: 10,
        workSeconds: 45,
        restSeconds: 60,
      );

      final map = pe.toMap();

      expect(map.containsKey('id'), false);
      expect(map['plan_id'], 1);
      expect(map['sets'], 3);
    });

    test('toMap includes id when present', () {
      final pe = PlanExercise(
        id: 10,
        planId: 1,
        exerciseId: 5,
        sortOrder: 0,
        sets: 3,
        workSeconds: 30,
        restSeconds: 30,
      );

      final map = pe.toMap();
      expect(map['id'], 10);
    });
  });
}
