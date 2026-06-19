import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final Map<String, DatabaseHelper> _instances = {};
  final String _dbName;
  Database? _database;

  factory DatabaseHelper({String dbName = 'fitness_coach.db'}) {
    return _instances.putIfAbsent(
        dbName, () => DatabaseHelper._internal(dbName));
  }

  DatabaseHelper._internal(this._dbName);

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        muscle_group TEXT NOT NULL,
        icon_code TEXT NOT NULL,
        description TEXT,
        is_preset INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE training_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE plan_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        sets INTEGER NOT NULL DEFAULT 3,
        reps INTEGER,
        work_seconds INTEGER NOT NULL DEFAULT 45,
        rest_seconds INTEGER NOT NULL DEFAULT 60,
        notes TEXT,
        FOREIGN KEY (plan_id) REFERENCES training_plans(id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL,
        plan_name TEXT NOT NULL,
        started_at TEXT NOT NULL,
        finished_at TEXT,
        duration_sec INTEGER NOT NULL DEFAULT 0,
        exercises_json TEXT NOT NULL DEFAULT '[]'
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE training_plans ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0');
    }
  }

  /// 仅用于测试：重置数据库
  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    await deleteDatabase(path);
    _database = null;
    _instances.remove(_dbName);
  }
}
