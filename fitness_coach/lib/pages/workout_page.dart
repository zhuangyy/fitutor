import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitness_coach/providers/workout_provider.dart';
import 'package:fitness_coach/providers/settings_provider.dart';
import 'package:fitness_coach/services/coach_engine.dart';
import 'package:fitness_coach/widgets/countdown_ring.dart';
import 'package:fitness_coach/pages/workout_summary_page.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<WorkoutProvider>().startWorkout();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await _showExitDialog();
        if (shouldExit && mounted) {
          context.read<WorkoutProvider>().stopWorkout();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Consumer2<WorkoutProvider, SettingsProvider>(
            builder: (context, provider, settings, _) {
              final state = provider.coachState;

              if (state.phase == CoachPhase.completed) {
                Future.microtask(() {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkoutSummaryPage(state: state),
                    ),
                  );
                });
                return const SizedBox.shrink();
              }

              final canTapPause = settings.tapToPause &&
                  (state.phase == CoachPhase.working ||
                      state.phase == CoachPhase.resting ||
                      state.phase == CoachPhase.postExerciseResting);

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: canTapPause ? () => provider.pause() : null,
                child: _buildWorkoutView(context, state),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutView(BuildContext context, CoachState state) {
    final isPaused = state.phase == CoachPhase.paused;
    final showPauseBtn = state.phase == CoachPhase.working ||
        state.phase == CoachPhase.resting;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  final shouldExit = await _showExitDialog();
                  if (shouldExit && mounted) {
                    context.read<WorkoutProvider>().stopWorkout();
                    Navigator.of(context).pop();
                  }
                },
              ),
              const Spacer(),
              if (showPauseBtn)
                IconButton(
                  icon: const Icon(Icons.pause_circle_filled, size: 32),
                  onPressed: () => context.read<WorkoutProvider>().pause(),
                ),
            ],
          ),
        ),
        const Spacer(),
        if (isPaused)
          _buildPausedView(context)
        else
          _buildActiveView(context, state),
        const Spacer(),
        if (!isPaused) _buildBottomInfo(context, state),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildActiveView(BuildContext context, CoachState state) {
    final phase = state.phase;

    if (phase == CoachPhase.announcing || phase == CoachPhase.transitioning) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            state.currentExercise?.exerciseName ?? '',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${state.currentExercise?.sets ?? 0}组 · ${state.currentExercise?.workSeconds ?? 0}秒/组',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(),
        ],
      );
    }

    if (phase == CoachPhase.working ||
        phase == CoachPhase.resting ||
        phase == CoachPhase.postExerciseResting) {
      final bool isWorking = phase == CoachPhase.working;
      final bool isPostExercise = phase == CoachPhase.postExerciseResting;
      final int total = isWorking
          ? (state.currentExercise?.workSeconds ?? 45)
          : isPostExercise
              ? (state.currentExercise?.afterRestSeconds ?? 0)
              : (state.currentExercise?.restSeconds ?? 60);

      Color ringColor;
      if (isWorking) {
        ringColor = Colors.red;
      } else if (isPostExercise) {
        ringColor = Colors.green;
      } else {
        ringColor = Colors.orange;
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CountdownRing(
            remainingSeconds: state.remainingSeconds,
            totalSeconds: total,
            size: 200,
            color: ringColor,
          ),
          const SizedBox(height: 24),
          Text(
            state.currentExercise?.exerciseName ?? '',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isWorking
                ? '第 ${state.currentSetIndex + 1} / ${state.totalSetsForCurrentExercise} 组'
                : isPostExercise
                    ? '动作完成，休息中...'
                    : '组间休息中...',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          if (!isWorking)
            TextButton.icon(
              onPressed: () => context.read<WorkoutProvider>().skipRest(),
              icon: const Icon(Icons.skip_next),
              label: const Text('跳过休息'),
            ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPausedView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.pause_circle_outline,
            size: 80, color: Colors.grey),
        const SizedBox(height: 16),
        const Text('暂停中',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: () => context.read<WorkoutProvider>().resume(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('继续'),
            ),
            const SizedBox(width: 24),
            OutlinedButton.icon(
              onPressed: () async {
                final shouldExit = await _showExitDialog();
                if (shouldExit && mounted) {
                  context.read<WorkoutProvider>().stopWorkout();
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.stop),
              label: const Text('结束训练'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomInfo(BuildContext context, CoachState state) {
    final progress = state.overallProgress;
    final exercises = state.exercises;
    final currentIdx = state.currentExerciseIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
            ),
          ),
          const SizedBox(height: 4),
          Text('${currentIdx + 1} / ${state.totalExercises} 动作',
              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            height: 104,
            child: ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (context, i) {
                final ex = exercises[i];
                final isPast = i < currentIdx;
                final isCurrent = i == currentIdx;

                IconData icon;
                Color iconColor;
                if (isPast) {
                  icon = Icons.check_circle;
                  iconColor = Colors.green;
                } else if (isCurrent) {
                  icon = Icons.play_circle_filled;
                  iconColor = Theme.of(context).colorScheme.primary;
                } else {
                  icon = Icons.circle_outlined;
                  iconColor = Colors.grey[400]!;
                }

                return SizedBox(
                  height: 28,
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: iconColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ex.exerciseName ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                            color: isPast ? Colors.grey[500] : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${ex.sets}组',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('结束训练？'),
        content: const Text('确定要结束当前训练吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('继续训练')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('结束', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
