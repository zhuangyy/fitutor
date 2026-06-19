import 'package:fitness_coach/database/database_helper.dart';
import 'package:fitness_coach/models/workout_session.dart';

class SessionDao {
  final DatabaseHelper _dbHelper;

  SessionDao({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<int> insert(WorkoutSession session) async {
    final db = await _dbHelper.database;
    return await db.insert('workout_sessions', session.toMap());
  }

  Future<List<WorkoutSession>> getAll() async {
    final db = await _dbHelper.database;
    final maps =
        await db.query('workout_sessions', orderBy: 'started_at DESC');
    return maps.map((m) => WorkoutSession.fromMap(m)).toList();
  }

  Future<WorkoutSession?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db
        .query('workout_sessions', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return WorkoutSession.fromMap(maps.first);
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db
        .delete('workout_sessions', where: 'id = ?', whereArgs: [id]);
  }

  /// 获取最近 N 次训练
  Future<List<WorkoutSession>> getRecent(int limit) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'workout_sessions',
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return maps.map((m) => WorkoutSession.fromMap(m)).toList();
  }
}
