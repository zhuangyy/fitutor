import 'package:flutter/material.dart';
import 'package:fitness_coach/database/exercise_dao.dart';
import 'package:fitness_coach/models/exercise.dart';

class ExerciseManagePage extends StatefulWidget {
  const ExerciseManagePage({super.key});

  @override
  State<ExerciseManagePage> createState() => _ExerciseManagePageState();
}

class _ExerciseManagePageState extends State<ExerciseManagePage> {
  final ExerciseDao _dao = ExerciseDao();
  final TextEditingController _searchController = TextEditingController();
  List<Exercise> _exercises = [];
  List<Exercise> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _exercises = await _dao.getAll();
    _filtered = _exercises;
    setState(() {});
  }

  void _filter(String query) {
    setState(() {
      _filtered = query.isEmpty
          ? _exercises
          : _exercises.where((e) => e.name.contains(query)).toList();
    });
  }

  Future<void> _delete(Exercise exercise) async {
    if (exercise.isPreset) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除动作'),
        content: Text('确定删除「${exercise.name}」吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _dao.delete(exercise.id!);
      _load();
    }
  }

  Future<void> _addCustom() async {
    final nameController = TextEditingController();
    final muscleController = TextEditingController();
    String category = '力量';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('创建自定义动作'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '动作名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: muscleController,
                  decoration: const InputDecoration(
                    labelText: '目标肌群',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('类型：'),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('力量'),
                      selected: category == '力量',
                      onSelected: (_) =>
                          setDialogState(() => category = '力量'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('计时'),
                      selected: category == '计时',
                      onSelected: (_) =>
                          setDialogState(() => category = '计时'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消')),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(ctx, {
                  'name': nameController.text.trim(),
                  'muscle': muscleController.text.trim().isEmpty
                      ? '其他'
                      : muscleController.text.trim(),
                  'category': category,
                });
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _dao.insert(Exercise(
        name: result['name']!,
        category: result['category']!,
        muscleGroup: result['muscle']!,
        iconCode: result['category'] == '力量' ? '59648' : '59654',
        isPreset: false,
        createdAt: DateTime.now().toIso8601String(),
      ));
      _load();
    }
  }

  Future<void> _edit(Exercise exercise) async {
    if (exercise.isPreset) return;
    final nameController = TextEditingController(text: exercise.name);
    final muscleController = TextEditingController(text: exercise.muscleGroup);
    String category = exercise.category;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('编辑动作'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: '动作名称', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: muscleController,
                  decoration: const InputDecoration(
                      labelText: '目标肌群', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('类型：'),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('力量'),
                      selected: category == '力量',
                      onSelected: (_) =>
                          setDialogState(() => category = '力量'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('计时'),
                      selected: category == '计时',
                      onSelected: (_) =>
                          setDialogState(() => category = '计时'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消')),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(ctx, {
                  'name': nameController.text.trim(),
                  'muscle': muscleController.text.trim().isEmpty
                      ? exercise.muscleGroup
                      : muscleController.text.trim(),
                  'category': category,
                });
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _dao.update(exercise.copyWith(
        name: result['name']!,
        muscleGroup: result['muscle']!,
        category: result['category']!,
      ));
      _load();
    }
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _filtered.removeAt(oldIndex);
      _filtered.insert(newIndex, item);
    });
    for (int i = 0; i < _exercises.length; i++) {
      final e = _exercises[i];
      final target = _filtered.indexOf(e);
      if (target >= 0 && e.sortOrder != target) {
        await _dao.update(e.copyWith(sortOrder: target));
      }
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final categories = <String, List<Exercise>>{};
    for (final e in _filtered) {
      categories.putIfAbsent(e.muscleGroup, () => []).add(e);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('动作管理')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '搜索动作...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filter,
            ),
          ),
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              children: categories.entries.map((entry) {
                return ExpansionTile(
                  title: Text(entry.key,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  initiallyExpanded: true,
                  children: entry.value.map((e) {
                    return ListTile(
                      leading: Icon(
                        e.category == '力量'
                            ? Icons.fitness_center
                            : Icons.timer,
                        color: e.isPreset ? Colors.grey[600] : Colors.blue,
                      ),
                      title: Text(e.name),
                      subtitle: Text(
                          '${e.category}${e.isPreset ? ' · 预设' : ' · 自定义'}'),
                      onTap: e.isPreset ? null : () => _edit(e),
                      trailing: e.isPreset
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red, size: 20),
                              onPressed: () => _delete(e),
                            ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustom,
        icon: const Icon(Icons.add),
        label: const Text('自定义动作'),
      ),
    );
  }
}
