import 'package:flutter/material.dart';
import 'package:fitness_coach/services/coach_engine.dart';

class WorkoutSummaryPage extends StatelessWidget {
  final CoachState state;

  const WorkoutSummaryPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final totalSeconds = state.exercises.fold<int>(
      0,
      (sum, e) =>
          sum + e.workSeconds * e.sets + e.restSeconds * (e.sets - 1),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text('训练完成！',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(_formatDuration(totalSeconds),
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary)),
                        const Text('总时长'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ...state.exercises.map((e) => ListTile(
                      leading: const Icon(Icons.check_circle,
                          color: Colors.green),
                      title: Text(e.exerciseName ?? ''),
                      subtitle: Text('${e.sets}组完成'),
                    )),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                    child: const Text('返回首页'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}秒';
    return '${m}分${s}秒';
  }
}
