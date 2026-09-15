import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_coach/models/workout_session.dart';

void main() {
  group('WorkoutSession', () {
    test('fromMap with exercises_json', () {
      final map = {
        'id': 1,
        'plan_id': 1,
        'plan_name': '推胸日',
        'started_at': '2024-12-20T14:30:00',
        'finished_at': '2024-12-20T15:02:15',
        'duration_sec': 1935,
        'exercises_json':
            '[{"exerciseName":"卧推","plannedSets":3,"completedSets":3}]',
      };
      final session = WorkoutSession.fromMap(map);
      expect(session.planName, '推胸日');
      expect(session.durationSec, 1935);
      expect(session.formattedDuration, '32分15秒');
      expect(session.completedExercises.length, 1);
      expect(session.completedExercises.first.exerciseName, '卧推');
    });

    test('toMap serializes exercises_json', () {
      final session = WorkoutSession(
        planId: 1,
        planName: '测试',
        startedAt: '2024-01-01T00:00:00',
        durationSec: 100,
        completedExercises: [
          CompletedExercise(
              exerciseName: '深蹲', plannedSets: 3, completedSets: 3),
        ],
      );
      final map = session.toMap();
      expect(map['exercises_json'], contains('深蹲'));
    });
  });
}
