import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitness_coach/providers/plan_provider.dart';
import 'package:fitness_coach/models/training_plan.dart';
import 'package:fitness_coach/models/plan_exercise.dart';
import 'package:fitness_coach/pages/exercise_picker.dart';

class PlanEditPage extends StatefulWidget {
  final TrainingPlan? plan;

  const PlanEditPage({super.key, this.plan});

  @override
  State<PlanEditPage> createState() => _PlanEditPageState();
}

class _PlanEditPageState extends State<PlanEditPage> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late List<PlanExercise> _exercises;
  bool _isNew = true;

  @override
  void initState() {
    super.initState();
    final plan = widget.plan;
    _isNew = plan == null;
    _nameController = TextEditingController(text: plan?.name ?? '');
    _descController = TextEditingController(text: plan?.description ?? '');
    _exercises = plan?.exercises.map((e) => e).toList() ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? '新建计划' : '编辑计划'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('保存'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '计划名称',
                hintText: '如：推胸日',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: '计划描述（可选）',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('动作列表',
                    style: Theme.of(context).textTheme.titleMedium),
                Text('${_exercises.length} 个动作',
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 8),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _exercises.length,
              onReorderItem: (oldIndex, newIndex) {
                setState(() {
                  final item = _exercises.removeAt(oldIndex);
                  _exercises.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final pe = _exercises[index];
                return Card(
                  key: ValueKey(pe.exerciseId * 1000 + index),
                  child: ListTile(
                    leading: const Icon(Icons.drag_handle),
                    title: Text(pe.exerciseName ?? '动作${index + 1}'),
                    subtitle: Text(
                        '${pe.sets}组 · ${pe.workSeconds}秒/组 · 休息${pe.restSeconds}秒'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () =>
                          setState(() => _exercises.removeAt(index)),
                    ),
                    onTap: () => _editExercise(index),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add),
                label: const Text('添加动作'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addExercise() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ExercisePicker(),
    );
    if (result != null) {
      setState(() {
        _exercises.add(PlanExercise(
          planId: widget.plan?.id ?? 0,
          exerciseId: result['exerciseId'] as int,
          sortOrder: _exercises.length,
          sets: result['sets'] as int,
          reps: result['reps'] as int?,
          workSeconds: result['workSeconds'] as int,
          restSeconds: result['restSeconds'] as int,
          exerciseName: result['exerciseName'] as String?,
        ));
      });
    }
  }

  void _editExercise(int index) async {
    final existing = _exercises[index];
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ExercisePicker(
        preSelectedExerciseId: existing.exerciseId,
        preSets: existing.sets,
        preReps: existing.reps,
        preWorkSeconds: existing.workSeconds,
        preRestSeconds: existing.restSeconds,
      ),
    );
    if (result != null) {
      setState(() {
        _exercises[index] = PlanExercise(
          planId: existing.planId,
          exerciseId: result['exerciseId'] as int,
          sortOrder: existing.sortOrder,
          sets: result['sets'] as int,
          reps: result['reps'] as int?,
          workSeconds: result['workSeconds'] as int,
          restSeconds: result['restSeconds'] as int,
          exerciseName: result['exerciseName'] as String?,
        );
      });
    }
  }

  void _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入计划名称')),
      );
      return;
    }

    final provider = context.read<PlanProvider>();
    final plan = TrainingPlan(
      id: widget.plan?.id,
      name: _nameController.text.trim(),
      description:
          _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      createdAt: widget.plan?.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );

    int planId;
    if (_isNew) {
      planId = await provider.createPlan(plan);
    } else {
      await provider.updatePlan(plan);
      planId = plan.id!;
    }

    final exercises =
        _exercises.map((e) => e.copyWith(planId: planId)).toList();
    await provider.savePlanExercises(planId, exercises);

    if (mounted) Navigator.pop(context);
  }
}
