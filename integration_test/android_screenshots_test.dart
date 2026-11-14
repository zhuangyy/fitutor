import 'dart:async';
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:fitness_coach/app.dart';
import 'package:fitness_coach/database/database_helper.dart';
import 'package:fitness_coach/database/exercise_dao.dart';
import 'package:fitness_coach/database/session_dao.dart';
import 'package:fitness_coach/models/exercise.dart';
import 'package:fitness_coach/models/training_plan.dart';
import 'package:fitness_coach/models/plan_exercise.dart';
import 'package:fitness_coach/models/workout_session.dart';
import 'package:fitness_coach/pages/workout_summary_page.dart';
import 'package:fitness_coach/pages/workout_page.dart';
import 'package:fitness_coach/providers/plan_provider.dart';
import 'package:fitness_coach/providers/settings_provider.dart';
import 'package:fitness_coach/providers/workout_provider.dart';
import 'package:fitness_coach/services/coach_engine.dart';
import 'package:fitness_coach/services/tts_service.dart';
import 'package:fitness_coach/services/haptic_service.dart';
import 'package:fitness_coach/services/notification_service.dart';
import 'package:fitness_coach/widgets/plan_card.dart';

/// 用 App 的真实界面生成应用商店截图。
///
/// 为什么不用 adb input：本机模拟器 ADB 触摸注入对 Flutter 无效（keyevent 有效，
/// tap/motionevent 不生效），所以用 integration_test 的 tester 驱动界面到目标状态，
/// 在每个场景打印 `@@SHOT <name>` 并停顿，由外部脚本 `adb exec-out screencap` 抓图。
///
/// 运行：
///   `flutter test integration_test/android_screenshots_test.dart -d <device-id>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('生成应用商店截图', (tester) async {
    // ---- 初始化数据库与预置动作（与 main() 一致）----
    final dbHelper = DatabaseHelper();
    await dbHelper.database;
    final exerciseDao = ExerciseDao();
    final jsonStr =
        await rootBundle.loadString('assets/data/preset_exercises.json');
    final List<dynamic> data = json.decode(jsonStr);
    await exerciseDao.syncPresetExercises(data
        .map((e) => Exercise(
              name: e['name'] as String,
              category: e['category'] as String,
              muscleGroup: e['muscle_group'] as String,
              iconCode: e['icon_code'] as String,
              description: e['description'] as String?,
              isPreset: true,
              createdAt: DateTime.now().toIso8601String(),
            ))
        .toList());

    // ---- 造示例数据（每次运行自建，不依赖既有数据）----
    final exercises = await exerciseDao.getAll();
    int exId(String name) => exercises.firstWhere((e) => e.name == name).id!;

    final planProvider = PlanProvider();
    final pid1 = await planProvider.createPlan(
        TrainingPlan(name: '胸背训练日', sortOrder: 0));
    await planProvider.savePlanExercises(pid1, [
      PlanExercise(
          planId: pid1, exerciseId: exId('杠铃卧推'), sortOrder: 0,
          sets: 4, reps: 10, workSeconds: 45, restSeconds: 60,
          afterRestSeconds: 60),
      PlanExercise(
          planId: pid1, exerciseId: exId('杠铃肩推'), sortOrder: 1,
          sets: 3, reps: 12, workSeconds: 40, restSeconds: 60),
      PlanExercise(
          planId: pid1, exerciseId: exId('硬拉'), sortOrder: 2,
          sets: 3, reps: 8, workSeconds: 50, restSeconds: 90),
    ]);

    final pid2 = await planProvider.createPlan(
        TrainingPlan(name: '腿部训练日', sortOrder: 1));
    await planProvider.savePlanExercises(pid2, [
      PlanExercise(
          planId: pid2, exerciseId: exId('杠铃深蹲'), sortOrder: 0,
          sets: 4, reps: 10, workSeconds: 50, restSeconds: 90,
          afterRestSeconds: 60),
      PlanExercise(
          planId: pid2, exerciseId: exId('哑铃弯举'), sortOrder: 1,
          sets: 3, reps: 15, workSeconds: 30, restSeconds: 45),
    ]);

    await SessionDao().insert(WorkoutSession(
      planId: pid1,
      planName: '胸背训练日',
      startedAt: '2026-09-14T19:05:00',
      finishedAt: '2026-09-14T19:42:00',
      durationSec: 2220,
      completedExercises: [
        CompletedExercise(exerciseName: '杠铃卧推', plannedSets: 4, completedSets: 4),
        CompletedExercise(exerciseName: '杠铃肩推', plannedSets: 3, completedSets: 3),
        CompletedExercise(exerciseName: '硬拉', plannedSets: 3, completedSets: 2),
      ],
    ));

    // ---- 启动 App ----
    final tts = TtsService();
    final haptic = HapticService();
    final notif = NotificationService();

    await tester.pumpWidget(FitnessCoachApp(
      ttsService: tts,
      hapticService: haptic,
      notificationService: notif,
    ));
    await tester.pumpAndSettle();

    // ① 计划列表
    await _shot(tester, '01-plans');

    // ② 计划编排页（长按计划卡片进入编辑）
    await tester.longPress(find.text('胸背训练日'));
    await tester.pumpAndSettle();
    await _shot(tester, '02-plan-edit');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // ⑤ 历史记录
    await tester.tap(find.text('历史').last);
    await tester.pumpAndSettle();
    await _shot(tester, '05-history');

    // ⑥ 设置页
    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();
    await _shot(tester, '06-settings');

    // 回到计划 tab
    await tester.tap(find.text('计划').last);
    await tester.pumpAndSettle();

    // ③ 训练中：点击计划卡片 → 确认弹窗 → 开始训练
    // （训练页有定时器，进入后不能用 pumpAndSettle）
    //
    // 注意：不要用 find.text('胸背训练日') —— 历史页也有同名条目，
    // 在 IndexedStack 里它仍然留在树中，会命中多个 widget 导致点位不稳定。
    // 这里用 PlanCard 限定作用域，只命中计划列表里的卡片。
    final planCard = find.widgetWithText(PlanCard, '胸背训练日');
    debugPrint('@@DIAG planCards=${find.byType(PlanCard).evaluate().length} '
        'scopedCards=${planCard.evaluate().length} '
        'nameTexts=${find.text('胸背训练日').evaluate().length}');
    await tester.tap(planCard.first);
    await tester.pumpAndSettle();
    debugPrint('@@DIAG dialogs=${find.byType(AlertDialog).evaluate().length} '
        'startButtons=${find.text('开始训练').evaluate().length}');

    if (find.text('开始训练').evaluate().isEmpty) {
      // 兜底：确认弹窗未出现时，直接走 provider 载入计划并进入训练页，
      // 保证 03-workout 这张截图一定拿得到（页面本身仍是真实 WorkoutPage）。
      debugPrint('@@DIAG fallback: dialog missing, entering workout directly');
      final ctx = tester.element(planCard.first);
      final plan = ctx
          .read<PlanProvider>()
          .plans
          .firstWhere((p) => p.name == '胸背训练日');
      ctx.read<WorkoutProvider>().loadPlan(
            plan,
            intervalSeconds: ctx.read<SettingsProvider>().reminderInterval,
          );
      unawaited(Navigator.of(ctx).push(
        MaterialPageRoute(builder: (_) => const WorkoutPage()),
      ));
    } else {
      await tester.tap(find.text('开始训练').first);
    }
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    // 先让倒计时真实走几秒，截图里能看到已消耗的进度环与递减的秒数，
    // 而不是「45 秒 + 满环」这种看起来像静态图的画面。
    await Future<void>.delayed(const Duration(seconds: 5));
    await tester.pump();
    debugPrint('@@SHOT 03-workout');
    await Future<void>.delayed(const Duration(seconds: 3));
    await tester.pump();

    // ④ 训练总结（直接构造页面，避免等待完整训练流程）
    // exerciseName 必须给：真实流程里由 DAO join 填充，这里手工构造，
    // 否则总结页每行只会显示「N组完成」而缺少动作名称。
    final summaryExercises = [
      PlanExercise(planId: pid1, exerciseId: exId('杠铃卧推'), sortOrder: 0,
          sets: 4, reps: 10, workSeconds: 45, restSeconds: 60,
          exerciseName: '杠铃卧推'),
      PlanExercise(planId: pid1, exerciseId: exId('杠铃肩推'), sortOrder: 1,
          sets: 3, reps: 12, workSeconds: 40, restSeconds: 60,
          exerciseName: '杠铃肩推'),
      PlanExercise(planId: pid1, exerciseId: exId('硬拉'), sortOrder: 2,
          sets: 3, reps: 8, workSeconds: 50, restSeconds: 90,
          exerciseName: '硬拉'),
    ];
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4CAF50)),
        useMaterial3: true,
      ),
      home: WorkoutSummaryPage(
        state: CoachState(
          phase: CoachPhase.completed,
          exercises: summaryExercises,
          totalExercises: summaryExercises.length,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await _shot(tester, '04-summary');
  });
}

Future<void> _shot(WidgetTester tester, String name) async {
  debugPrint('@@SHOT $name');
  await tester.pumpAndSettle();
  await Future<void>.delayed(const Duration(seconds: 5));
}
