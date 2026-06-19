import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitness_coach/providers/plan_provider.dart';
import 'package:fitness_coach/providers/workout_provider.dart';
import 'package:fitness_coach/providers/settings_provider.dart';
import 'package:fitness_coach/models/training_plan.dart';
import 'package:fitness_coach/pages/plan_edit_page.dart';
import 'package:fitness_coach/pages/workout_page.dart';
import 'package:fitness_coach/pages/history_page.dart';
import 'package:fitness_coach/pages/settings_page.dart';
import 'package:fitness_coach/pages/exercise_manage_page.dart';
import 'package:fitness_coach/widgets/plan_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentTab = 0;

  final _pages = const [
    _PlanListTab(),
    ExerciseManagePage(),
    HistoryPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) => setState(() => _currentTab = index),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.fitness_center), label: '计划'),
          NavigationDestination(
              icon: Icon(Icons.sports_gymnastics), label: '动作'),
          NavigationDestination(icon: Icon(Icons.history), label: '历史'),
          NavigationDestination(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}

class _PlanListTab extends StatelessWidget {
  const _PlanListTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🏋️ 跟我练')),
      body: Consumer<PlanProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fitness_center,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('还没有训练计划',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('点击下方按钮创建第一个计划',
                      style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.plans.length,
            onReorder: (oldIndex, newIndex) {
              provider.reorderPlans(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final plan = provider.plans[index];
              return PlanCard(
                key: ValueKey(plan.id),
                plan: plan,
                onTap: () => _onStartWorkout(context, plan),
                onLongPress: () => _onEditPlan(context, plan),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onCreatePlan(context),
        icon: const Icon(Icons.add),
        label: const Text('新建计划'),
      ),
    );
  }

  void _onStartWorkout(BuildContext context, TrainingPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(plan.name),
        content:
            Text('${plan.exerciseCount} 个动作 · ${plan.estimatedDurationText}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('开始训练')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final interval = context.read<SettingsProvider>().reminderInterval;
      context.read<WorkoutProvider>().loadPlan(plan, intervalSeconds: interval);
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const WorkoutPage()));
    }
  }

  void _onEditPlan(BuildContext context, TrainingPlan plan) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlanEditPage(plan: plan)),
    );
    if (context.mounted) context.read<PlanProvider>().loadPlans();
  }

  void _onCreatePlan(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlanEditPage()),
    );
    if (context.mounted) context.read<PlanProvider>().loadPlans();
  }
}
