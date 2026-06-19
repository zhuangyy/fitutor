import 'package:flutter/material.dart';
import 'package:fitness_coach/database/exercise_dao.dart';
import 'package:fitness_coach/models/exercise.dart';

class ExercisePicker extends StatefulWidget {
  final int? preSelectedExerciseId;
  final int preSets;
  final int? preReps;
  final int preWorkSeconds;
  final int preRestSeconds;

  const ExercisePicker({
    super.key,
    this.preSelectedExerciseId,
    this.preSets = 3,
    this.preReps,
    this.preWorkSeconds = 45,
    this.preRestSeconds = 60,
  });

  @override
  State<ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<ExercisePicker> {
  final ExerciseDao _dao = ExerciseDao();
  List<Exercise> _exercises = [];
  List<Exercise> _filtered = [];
  Exercise? _selected;
  final TextEditingController _searchController = TextEditingController();

  late int _sets;
  int? _reps;
  late int _workSeconds;
  late int _restSeconds;

  bool _showParams = false;

  @override
  void initState() {
    super.initState();
    _sets = widget.preSets;
    _reps = widget.preReps;
    _workSeconds = widget.preWorkSeconds;
    _restSeconds = widget.preRestSeconds;
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    _exercises = await _dao.getAll();
    _filtered = _exercises;
    if (widget.preSelectedExerciseId != null) {
      _selected = _exercises.firstWhere(
        (e) => e.id == widget.preSelectedExerciseId,
        orElse: () => _exercises.first,
      );
      _showParams = true;
    }
    setState(() {});
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _exercises;
      } else {
        _filtered = _exercises
            .where((e) => e.name.contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showParams && _selected != null) {
      return _buildParamsView();
    }
    return _buildExerciseList();
  }

  Widget _buildExerciseList() {
    final categories = <String, List<Exercise>>{};
    for (final e in _filtered) {
      categories.putIfAbsent(e.muscleGroup, () => []).add(e);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('选择动作', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '搜索动作...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filter,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  ...categories.entries.map((entry) {
                    return ExpansionTile(
                      title: Text(entry.key,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      initiallyExpanded: false,
                      children: entry.value
                          .map((e) => ListTile(
                                leading: Icon(e.category == '力量'
                                    ? Icons.fitness_center
                                    : Icons.timer),
                                title: Text(e.name),
                                subtitle: Text(e.category),
                                onTap: () {
                                  setState(() {
                                    _selected = e;
                                    _showParams = true;
                                  });
                                },
                              ))
                          .toList(),
                    );
                  }),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline,
                        color: Colors.green),
                    title: const Text('自定义动作'),
                    subtitle: const Text('创建新的训练动作'),
                    onTap: _addCustomExercise,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParamsView() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _showParams = false),
                ),
                Text('设置参数：${_selected!.name}',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            _buildNumberField(
                '训练时长（秒/组）', _workSeconds, (v) => _workSeconds = v),
            const SizedBox(height: 12),
            _buildNumberField('组数', _sets, (v) => _sets = v),
            const SizedBox(height: 12),
            _buildNumberField(
                '次数（可选，力量训练）', _reps ?? 0, (v) => _reps = v > 0 ? v : null),
            const SizedBox(height: 12),
            _buildNumberField(
                '组间休息（秒）', _restSeconds, (v) => _restSeconds = v),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'exerciseId': _selected!.id,
                    'exerciseName': _selected!.name,
                    'sets': _sets,
                    'reps': _reps,
                    'workSeconds': _workSeconds,
                    'restSeconds': _restSeconds,
                  });
                },
                child: const Text('添加到计划'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCustomExercise() async {
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
                    hintText: '如：罗马尼亚硬拉',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: muscleController,
                  decoration: const InputDecoration(
                    labelText: '目标肌群',
                    hintText: '如：背、腿、胸',
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

    if (result != null && mounted) {
      final exercise = Exercise(
        name: result['name']!,
        category: result['category']!,
        muscleGroup: result['muscle']!,
        iconCode: result['category'] == '力量' ? '59648' : '59654',
        isPreset: false,
        createdAt: DateTime.now().toIso8601String(),
      );
      final id = await _dao.insert(exercise);
      _selected = exercise.copyWith(id: id);
      _showParams = true;
      _loadExercises();
    }
  }

  Widget _buildNumberField(
      String label, int value, Function(int) onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        SizedBox(
          width: 120,
          child: TextField(
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: value.toString()),
            decoration: const InputDecoration(
                border: OutlineInputBorder(), isDense: true),
            onChanged: (v) => onChanged(int.tryParse(v) ?? value),
          ),
        ),
      ],
    );
  }
}
