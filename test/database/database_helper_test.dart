import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fitness_coach/database/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('DatabaseHelper is singleton', () {
    final db1 = DatabaseHelper();
    final db2 = DatabaseHelper();
    expect(identical(db1, db2), true);
  });

  test('database opens successfully with 4 tables', () async {
    final db = await DatabaseHelper().database;
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name");
    final tableNames = tables.map((t) => t['name'] as String).toList();
    expect(tableNames, contains('exercises'));
    expect(tableNames, contains('training_plans'));
    expect(tableNames, contains('plan_exercises'));
    expect(tableNames, contains('workout_sessions'));
  });
}
