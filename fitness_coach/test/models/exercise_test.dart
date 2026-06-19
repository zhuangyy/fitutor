import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_coach/models/exercise.dart';

void main() {
  group('Exercise', () {
    test('fromMap creates Exercise with all fields', () {
      final map = {
        'id': 1,
        'name': '杠铃卧推',
        'category': '力量',
        'muscle_group': '胸',
        'icon_code': '59648',
        'description': '平板卧推',
        'is_preset': 1,
        'created_at': '2024-01-01',
      };

      final exercise = Exercise.fromMap(map);

      expect(exercise.id, 1);
      expect(exercise.name, '杠铃卧推');
      expect(exercise.category, '力量');
      expect(exercise.muscleGroup, '胸');
      expect(exercise.iconCode, '59648');
      expect(exercise.isPreset, true);
    });

    test('toMap converts Exercise to map correctly', () {
      final exercise = Exercise(
        id: 1,
        name: '深蹲',
        category: '力量',
        muscleGroup: '腿',
        iconCode: '12345',
        description: '杠铃深蹲',
        isPreset: false,
        createdAt: '2024-01-01',
      );

      final map = exercise.toMap();

      expect(map['id'], 1);
      expect(map['name'], '深蹲');
      expect(map['category'], '力量');
      expect(map['is_preset'], 0);
    });

    test('isPreset setter/getter works with int', () {
      final exercise =
          Exercise(name: '', category: '', muscleGroup: '', iconCode: '');
      exercise.isPreset = true;
      expect(exercise.isPreset, true);
      exercise.isPreset = false;
      expect(exercise.isPreset, false);
    });

    test('toString returns name', () {
      final exercise =
          Exercise(name: '卧推', category: '', muscleGroup: '', iconCode: '');
      expect(exercise.toString(), '卧推');
    });
  });
}
