import 'package:flutter/material.dart';
import 'package:fitness_coach/database/session_dao.dart';
import 'package:fitness_coach/models/workout_session.dart';

class HistoryDetailPage extends StatelessWidget {
  final WorkoutSession session;

  const HistoryDetailPage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('训练详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('删除记录'),
                  content: const Text('确定删除这条训练记录吗？'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('取消')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('删除',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await SessionDao().delete(session.id!);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(session.planName,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(session.formattedDate,
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 4),
            Text('总时长：${session.formattedDuration}',
                style: TextStyle(color: Colors.grey[600])),
            const Divider(height: 32),
            ...session.completedExercises.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text('${e.exerciseName}  '
                          '${e.completedSets}/${e.plannedSets}组'),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
