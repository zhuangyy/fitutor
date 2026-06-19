import 'plan_exercise.dart';

class TrainingPlan {
  final int? id;
  final String name;
  final String? description;
  final String? createdAt;
  String? updatedAt;
  List<PlanExercise> exercises;

  TrainingPlan({
    this.id,
    required this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
    List<PlanExercise>? exercises,
  }) : exercises = exercises ?? [];

  factory TrainingPlan.fromMap(Map<String, dynamic> map) {
    return TrainingPlan(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  TrainingPlan copyWith({
    int? id,
    String? name,
    String? description,
    String? createdAt,
    String? updatedAt,
    List<PlanExercise>? exercises,
  }) {
    return TrainingPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      exercises: exercises ?? List.from(this.exercises),
    );
  }

  /// 计划总动作数
  int get exerciseCount => exercises.length;

  /// 计划预估总时长（秒）
  int get estimatedDurationSeconds =>
      exercises.fold(0, (sum, e) => sum + e.estimatedDurationSeconds);

  /// 格式化预估时长：如 "约35分钟"
  String get estimatedDurationText {
    final minutes = estimatedDurationSeconds ~/ 60;
    if (minutes < 1) return '不到1分钟';
    return '约$minutes分钟';
  }

  @override
  String toString() => name;
}
