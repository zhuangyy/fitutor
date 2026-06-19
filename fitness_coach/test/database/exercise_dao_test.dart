import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fitness_coach/database/database_helper.dart';
import 'package:fitness_coach/database/exercise_dao.dart';
import 'package:fitness_coach/models/exercise.dart';

void main() {
  late DatabaseHelper dbHelper;
  late ExerciseDao dao;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper(dbName: 'test_exercise_dao.db');
    await dbHelper.resetDatabase();
    await dbHelper.database;
    dao = ExerciseDao(dbHelper: dbHelper);
  });

  test('insert and getById', () async {
    final exercise = Exercise(
      name: '测试动作',
      category: '力量',
      muscleGroup: '胸',
      iconCode: '123',
      isPreset: false,
      createdAt: DateTime.now().toIso8601String(),
    );
    final id = await dao.insert(exercise);
    expect(id, greaterThan(0));

    final fetched = await dao.getById(id);
    expect(fetched, isNotNull);
    expect(fetched!.name, '测试动作');
  });

  test('getAll returns exercises ordered by category, name', () async {
    await dao.insert(Exercise(
        name: 'B',
        category: '力量',
        muscleGroup: '',
        iconCode: '',
        createdAt: DateTime.now().toIso8601String()));
    await dao.insert(Exercise(
        name: 'A',
        category: '力量',
        muscleGroup: '',
        iconCode: '',
        createdAt: DateTime.now().toIso8601String()));
    final all = await dao.getAll();
    expect(all.length, greaterThanOrEqualTo(2));
    expect(all.first.name, 'A');
  });

  test('delete removes exercise', () async {
    final id = await dao.insert(Exercise(
        name: 'X',
        category: '计时',
        muscleGroup: '',
        iconCode: '',
        createdAt: DateTime.now().toIso8601String()));
    await dao.delete(id);
    final fetched = await dao.getById(id);
    expect(fetched, isNull);
  });

  test('update modifies exercise', () async {
    final id = await dao.insert(Exercise(
        name: '原名称',
        category: '力量',
        muscleGroup: '胸',
        iconCode: '',
        createdAt: DateTime.now().toIso8601String()));
    final updated = Exercise(
        id: id,
        name: '新名称',
        category: '力量',
        muscleGroup: '胸',
        iconCode: '',
        createdAt: DateTime.now().toIso8601String());
    await dao.update(updated);
    final fetched = await dao.getById(id);
    expect(fetched!.name, '新名称');
  });
}
