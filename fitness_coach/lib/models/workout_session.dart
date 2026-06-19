import 'dart:convert';

class CompletedExercise {
  final String exerciseName;
  final int plannedSets;
  final int completedSets;

  CompletedExercise({
    required this.exerciseName,
    required this.plannedSets,
    required this.completedSets,
  });

  Map<String, dynamic> toJson() => {
        'exerciseName': exerciseName,
        'plannedSets': plannedSets,
        'completedSets': completedSets,
      };

  factory CompletedExercise.fromJson(Map<String, dynamic> json) {
    return CompletedExercise(
      exerciseName: json['exerciseName'] as String,
      plannedSets: json['plannedSets'] as int,
      completedSets: json['completedSets'] as int,
    );
  }
}

class WorkoutSession {
  final int? id;
  final int planId;
  final String planName;
  final String startedAt;
  final String? finishedAt;
  final int durationSec;
  final List<CompletedExercise> completedExercises;

  WorkoutSession({
    this.id,
    required this.planId,
    required this.planName,
    required this.startedAt,
    this.finishedAt,
    this.durationSec = 0,
    List<CompletedExercise>? completedExercises,
  }) : completedExercises = completedExercises ?? [];

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    List<CompletedExercise> exercises = [];
    if (map['exercises_json'] != null) {
      final list = json.decode(map['exercises_json'] as String) as List;
      exercises = list.map((e) => CompletedExercise.fromJson(e)).toList();
    }
    return WorkoutSession(
      id: map['id'] as int?,
      planId: map['plan_id'] as int,
      planName: map['plan_name'] as String,
      startedAt: map['started_at'] as String,
      finishedAt: map['finished_at'] as String?,
      durationSec: map['duration_sec'] as int? ?? 0,
      completedExercises: exercises,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'plan_id': planId,
      'plan_name': planName,
      'started_at': startedAt,
      'finished_at': finishedAt,
      'duration_sec': durationSec,
      'exercises_json':
          json.encode(completedExercises.map((e) => e.toJson()).toList()),
    };
  }

  /// 格式化时长：如 "32分15秒"
  String get formattedDuration {
    final minutes = durationSec ~/ 60;
    final seconds = durationSec % 60;
    if (minutes == 0) return '${seconds}秒';
    return '${minutes}分${seconds}秒';
  }

  /// 格式化日期显示
  String get formattedDate {
    try {
      final dt = DateTime.parse(startedAt);
      return '${dt.month}月${dt.day}日 '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return startedAt;
    }
  }
}
