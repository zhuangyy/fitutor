class PlanExercise {
  final int? id;
  final int planId;
  final int exerciseId;
  final int sortOrder;
  final int sets;
  final int? reps;           // 力量训练有次数，计时训练为 null
  final int workSeconds;     // 每组训练时长（秒）
  final int restSeconds;     // 组间休息（秒）
  final String? notes;

  // 关联数据（非数据库字段，由 DAO 层 join 填充）
  String? exerciseName;
  String? exerciseCategory;
  String? exerciseMuscleGroup;
  String? exerciseIconCode;

  PlanExercise({
    this.id,
    required this.planId,
    required this.exerciseId,
    required this.sortOrder,
    required this.sets,
    this.reps,
    required this.workSeconds,
    required this.restSeconds,
    this.notes,
    this.exerciseName,
    this.exerciseCategory,
    this.exerciseMuscleGroup,
    this.exerciseIconCode,
  });

  factory PlanExercise.fromMap(Map<String, dynamic> map) {
    return PlanExercise(
      id: map['id'] as int?,
      planId: map['plan_id'] as int,
      exerciseId: map['exercise_id'] as int,
      sortOrder: map['sort_order'] as int,
      sets: map['sets'] as int,
      reps: map['reps'] as int?,
      workSeconds: map['work_seconds'] as int,
      restSeconds: map['rest_seconds'] as int,
      notes: map['notes'] as String?,
      exerciseName: map['exercise_name'] as String?,
      exerciseCategory: map['exercise_category'] as String?,
      exerciseMuscleGroup: map['exercise_muscle_group'] as String?,
      exerciseIconCode: map['exercise_icon_code'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'plan_id': planId,
      'exercise_id': exerciseId,
      'sort_order': sortOrder,
      'sets': sets,
      'reps': reps,
      'work_seconds': workSeconds,
      'rest_seconds': restSeconds,
      'notes': notes,
    };
  }

  PlanExercise copyWith({
    int? id,
    int? planId,
    int? exerciseId,
    int? sortOrder,
    int? sets,
    int? reps,
    int? workSeconds,
    int? restSeconds,
    String? notes,
  }) {
    return PlanExercise(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      exerciseId: exerciseId ?? this.exerciseId,
      sortOrder: sortOrder ?? this.sortOrder,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      workSeconds: workSeconds ?? this.workSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      notes: notes ?? this.notes,
      exerciseName: exerciseName,
      exerciseCategory: exerciseCategory,
      exerciseMuscleGroup: exerciseMuscleGroup,
      exerciseIconCode: exerciseIconCode,
    );
  }

  /// 该动作的总时长估算（秒）: 组数 × (训练时长 + 休息时间)
  int get estimatedDurationSeconds => sets * (workSeconds + restSeconds);
}
