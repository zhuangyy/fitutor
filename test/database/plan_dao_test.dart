import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fitness_coach/database/database_helper.dart';
import 'package:fitness_coach/database/exercise_dao.dart';
import 'package:fitness_coach/database/plan_dao.dart';
import 'package:fitness_coach/models/exercise.dart';
import 'package:fitness_coach/models/training_plan.dart';
import 'package:fitness_coach/models/plan_exercise.dart';

void main() {
  late DatabaseHelper dbHelper;
  late PlanDao planDao;
  late ExerciseDao exerciseDao;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper(dbName: 'test_plan_dao.db');
    await dbHelper.resetDatabase();
    await dbHelper.database;
    planDao = PlanDao(dbHelper: dbHelper);
    exerciseDao = ExerciseDao(dbHelper: dbHelper);
  });

  test('insert and get plan with exercises', () async {
    final exId = await exerciseDao.insert(Exercise(
      name: '卧推',
      category: '力量',
      muscleGroup: '胸',
      iconCode: '',
      createdAt: DateTime.now().toIso8601String(),
    ));

    final planId = await planDao.insertPlan(TrainingPlan(
      name: '推胸日',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    ));

    await planDao.insertPlanExercise(PlanExercise(
      planId: planId,
      exerciseId: exId,
      sortOrder: 0,
      sets: 3,
      reps: 10,
      workSeconds: 45,
      restSeconds: 60,
    ));

    final plan = await planDao.getPlanById(planId);
    expect(plan, isNotNull);
    expect(plan!.name, '推胸日');
    expect(plan.exercises.length, 1);
    expect(plan.exercises.first.exerciseName, '卧推');
    expect(plan.exercises.first.sets, 3);
  });

  test('delete plan cascades to plan_exercises', () async {
    final exId = await exerciseDao.insert(Exercise(
      name: '深蹲',
      category: '力量',
      muscleGroup: '腿',
      iconCode: '',
      createdAt: DateTime.now().toIso8601String(),
    ));
    final planId = await planDao.insertPlan(TrainingPlan(
      name: '腿部日',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    ));
    await planDao.insertPlanExercise(PlanExercise(
      planId: planId,
      exerciseId: exId,
      sortOrder: 0,
      sets: 3,
      workSeconds: 60,
      restSeconds: 90,
    ));

    await planDao.deletePlan(planId);
    final deleted = await planDao.getPlanById(planId);
    expect(deleted, isNull);
  });
}
