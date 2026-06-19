import 'package:fitness_coach/database/database_helper.dart';
import 'package:fitness_coach/models/training_plan.dart';
import 'package:fitness_coach/models/plan_exercise.dart';

class PlanDao {
  final DatabaseHelper _dbHelper;

  PlanDao({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  // ─── TrainingPlan CRUD ───

  Future<int> insertPlan(TrainingPlan plan) async {
    final db = await _dbHelper.database;
    return await db.insert('training_plans', plan.toMap());
  }

  Future<List<TrainingPlan>> getAllPlans() async {
    final db = await _dbHelper.database;
    final maps = await db.query('training_plans', orderBy: 'sort_order, updated_at DESC');
    final plans = maps.map((m) => TrainingPlan.fromMap(m)).toList();
    for (final plan in plans) {
      plan.exercises = await _getPlanExercises(plan.id!);
    }
    return plans;
  }

  Future<TrainingPlan?> getPlanById(int id) async {
    final db = await _dbHelper.database;
    final maps =
        await db.query('training_plans', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final plan = TrainingPlan.fromMap(maps.first);
    plan.exercises = await _getPlanExercises(id);
    return plan;
  }

  Future<int> updatePlan(TrainingPlan plan) async {
    final db = await _dbHelper.database;
    return await db.update(
      'training_plans',
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  Future<int> deletePlan(int id) async {
    final db = await _dbHelper.database;
    await db.delete('plan_exercises', where: 'plan_id = ?', whereArgs: [id]);
    return await db.delete('training_plans', where: 'id = ?', whereArgs: [id]);
  }

  // ─── PlanExercise CRUD ───

  Future<int> insertPlanExercise(PlanExercise pe) async {
    final db = await _dbHelper.database;
    return await db.insert('plan_exercises', pe.toMap());
  }

  Future<void> updatePlanExercise(PlanExercise pe) async {
    final db = await _dbHelper.database;
    await db.update('plan_exercises', pe.toMap(),
        where: 'id = ?', whereArgs: [pe.id]);
  }

  Future<void> deletePlanExercise(int id) async {
    final db = await _dbHelper.database;
    await db.delete('plan_exercises', where: 'id = ?', whereArgs: [id]);
  }

  /// 替换某个计划下的全部动作（批量删除 + 批量插入）
  Future<void> replacePlanExercises(
      int planId, List<PlanExercise> exercises) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn
          .delete('plan_exercises', where: 'plan_id = ?', whereArgs: [planId]);
      for (int i = 0; i < exercises.length; i++) {
        final pe = exercises[i].copyWith(sortOrder: i);
        await txn.insert('plan_exercises', pe.toMap());
      }
    });
  }

  // ─── 内部方法 ───

  Future<List<PlanExercise>> _getPlanExercises(int planId) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT pe.*, e.name as exercise_name, e.category as exercise_category,
             e.muscle_group as exercise_muscle_group, e.icon_code as exercise_icon_code
      FROM plan_exercises pe
      JOIN exercises e ON pe.exercise_id = e.id
      WHERE pe.plan_id = ?
      ORDER BY pe.sort_order
    ''', [planId]);
    return maps.map((m) => PlanExercise.fromMap(m)).toList();
  }
}
