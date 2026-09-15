import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:fitness_coach/app.dart';
import 'package:fitness_coach/database/database_helper.dart';
import 'package:fitness_coach/database/exercise_dao.dart';
import 'package:fitness_coach/services/tts_service.dart';
import 'package:fitness_coach/services/haptic_service.dart';
import 'package:fitness_coach/services/notification_service.dart';
import 'package:fitness_coach/models/exercise.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化数据库
  final dbHelper = DatabaseHelper();
  await dbHelper.database;

  // 导入预置动作（增量：只添加新增的预设，不覆盖已有）
  final exerciseDao = ExerciseDao();
  final jsonStr =
      await rootBundle.loadString('assets/data/preset_exercises.json');
  final List<dynamic> data = json.decode(jsonStr);
  final newExercises = data
      .map((e) => Exercise(
            name: e['name'] as String,
            category: e['category'] as String,
            muscleGroup: e['muscle_group'] as String,
            iconCode: e['icon_code'] as String,
            description: e['description'] as String?,
            isPreset: true,
            createdAt: DateTime.now().toIso8601String(),
          ))
      .toList();
  await exerciseDao.syncPresetExercises(newExercises);

  // 初始化服务
  final ttsService = TtsService();
  await ttsService.init();

  final hapticService = HapticService();

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(FitnessCoachApp(
    ttsService: ttsService,
    hapticService: hapticService,
    notificationService: notificationService,
  ));

  // 首帧渲染后再播放欢迎词，避免白屏时发声
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ttsService.warmUp();
  });
}
