import 'package:fitness_coach/database/database_helper.dart';
import 'package:fitness_coach/models/exercise.dart';

class ExerciseDao {
  final DatabaseHelper _dbHelper;

  ExerciseDao({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<int> insert(Exercise exercise) async {
    final db = await _dbHelper.database;
    return await db.insert('exercises', exercise.toMap());
  }

  Future<List<Exercise>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('exercises', orderBy: 'sort_order, category, name');
    return maps.map((m) => Exercise.fromMap(m)).toList();
  }

  Future<Exercise?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('exercises', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Exercise.fromMap(maps.first);
  }

  Future<List<Exercise>> getByCategory(String category) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'exercises',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'name',
    );
    return maps.map((m) => Exercise.fromMap(m)).toList();
  }

  Future<List<Exercise>> getCustom() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'exercises',
      where: 'is_preset = 0',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Exercise.fromMap(m)).toList();
  }

  Future<int> update(Exercise exercise) async {
    final db = await _dbHelper.database;
    return await db.update(
      'exercises',
      exercise.toMap(),
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  /// 批量插入预置动作
  Future<void> insertPresetExercises(List<Exercise> exercises) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final exercise in exercises) {
      batch.insert('exercises', exercise.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// 检查是否已有预置数据
  Future<bool> hasPresetExercises() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM exercises WHERE is_preset = 1');
    return (result.first['cnt'] as int) > 0;
  }

  /// 增量同步预置动作：只插入数据库中不存在的（按名称去重）
  Future<void> syncPresetExercises(List<Exercise> exercises) async {
    final db = await _dbHelper.database;
    final existing =
        await db.rawQuery('SELECT name FROM exercises WHERE is_preset = 1');
    final existingNames = existing.map((e) => e['name'] as String).toSet();
    final toInsert = exercises
        .where((e) => !existingNames.contains(e.name))
        .toList();
    if (toInsert.isNotEmpty) {
      final batch = db.batch();
      for (final exercise in toInsert) {
        batch.insert('exercises', exercise.toMap());
      }
      await batch.commit(noResult: true);
    }
  }
}
