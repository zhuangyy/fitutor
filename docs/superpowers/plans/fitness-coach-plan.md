# Fitness Coach App — 实施计划

> **For agentic workers:** 按 Task 顺序逐任务实施。每个 task 包含多个步骤，使用 checkbox (`- [ ]`) 跟踪。
> 每个 Task 完成后运行 `flutter test` 确认，然后 commit。

**Goal:** 构建一个离线 Flutter 健身跟练 App，包含训练计划制定、虚拟教练引导（TTS+震动+计时器）、训练历史记录和设置。

**Architecture:** Flutter + Provider 状态管理 + sqflite 本地数据库。4 张数据表（exercises, training_plans, plan_exercises, workout_sessions），CoachEngine 状态机驱动跟练流程，flutter_tts + HapticFeedback 提供多模态教练反馈。

**Tech Stack:** Flutter 3.x / Dart 3.x / sqflite / Provider / flutter_tts / flutter_local_notifications

**参考设计文档:** `docs/superpowers/specs/fitness-coach-design.md`

---

## Phase 0: 环境搭建 & 项目骨架

### Task 0.1: 安装 Flutter SDK

- [ ] **Step 1: 安装 Flutter**

根据操作系统执行：

**macOS:**
```bash
brew install --cask flutter
```

**或手动下载：** https://docs.flutter.dev/get-started/install

- [ ] **Step 2: 验证安装**

```bash
flutter doctor
```
预期：至少 Android toolchain 和 Xcode 部分显示绿色勾。黄色警告可暂时忽略。

- [ ] **Step 3: 配置编辑器**

安装 VS Code 扩展 `Flutter` 和 `Dart`（在 VS Code 扩展市场搜索）。

### Task 0.2: 创建项目

- [ ] **Step 1: 创建 Flutter 项目**

```bash
cd /Volumes/SYAN/my/fitutor
flutter create --org com.fitutor fitness_coach
```

验证：
```bash
ls fitness_coach/lib/main.dart
```
预期：文件存在。

- [ ] **Step 2: 添加依赖 — 编辑 pubspec.yaml**

修改 `fitness_coach/pubspec.yaml`，在 `dependencies:` 下添加：

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6
  sqflite: ^2.3.0
  path: ^1.8.0
  provider: ^6.1.0
  flutter_tts: ^4.0.0
  flutter_local_notifications: ^17.0.0
  intl: ^0.19.0
  uuid: ^4.2.0
```

- [ ] **Step 3: 安装依赖**

```bash
cd fitness_coach
flutter pub get
```
预期：`exit code 0`，无错误。

- [ ] **Step 4: 验证项目可运行**

```bash
cd fitness_coach
flutter run
```
预期：默认计数器 App 在模拟器或真机上显示。然后停止（Ctrl+C）。

- [ ] **Step 5: Commit**

```bash
cd fitness_coach
git add pubspec.yaml pubspec.lock
git commit -m "chore: init Flutter project with dependencies"
```

### Task 0.3: 创建目录结构

- [ ] **Step 1: 创建所有目录**

```bash
cd fitness_coach
mkdir -p lib/models
mkdir -p lib/database
mkdir -p lib/services
mkdir -p lib/providers
mkdir -p lib/pages
mkdir -p lib/widgets
mkdir -p assets/data
```

验证：
```bash
ls -d lib/*/
```
预期：列出 6 个目录。

- [ ] **Step 2: 创建预置动作 JSON 文件**

写入 `assets/data/preset_exercises.json`：

```json
[
  {"name":"杠铃卧推","category":"力量","muscle_group":"胸","icon_code":"59648","description":"仰卧于平板凳，双手握杠铃，下放至胸前再推起"},
  {"name":"上斜卧推","category":"力量","muscle_group":"胸","icon_code":"59648","description":"上斜凳角度约30-45度，杠铃推举"},
  {"name":"哑铃飞鸟","category":"力量","muscle_group":"胸","icon_code":"59648","description":"仰卧，双手持哑铃向两侧打开再合拢"},
  {"name":"杠铃深蹲","category":"力量","muscle_group":"腿","icon_code":"59649","description":"杠铃置于斜方肌上，下蹲至大腿平行地面"},
  {"name":"腿举","category":"力量","muscle_group":"腿","icon_code":"59649","description":"坐于腿举机，双脚推踏板"},
  {"name":"硬拉","category":"力量","muscle_group":"背","icon_code":"59650","description":"双脚与肩同宽，屈髋屈膝握杠铃，展髋站起"},
  {"name":"引体向上","category":"力量","muscle_group":"背","icon_code":"59650","description":"正手握杠，身体上拉至下巴过杠"},
  {"name":"杠铃划船","category":"力量","muscle_group":"背","icon_code":"59650","description":"俯身，杠铃沿大腿方向上拉至腹部"},
  {"name":"哑铃弯举","category":"力量","muscle_group":"手臂","icon_code":"59651","description":"站立，双手持哑铃弯举"},
  {"name":"三头下压","category":"力量","muscle_group":"手臂","icon_code":"59651","description":"龙门架绳索下压，锻炼肱三头肌"},
  {"name":"侧平举","category":"力量","muscle_group":"肩","icon_code":"59652","description":"站立，双手持哑铃向两侧平举"},
  {"name":"杠铃肩推","category":"力量","muscle_group":"肩","icon_code":"59652","description":"坐姿或站姿，杠铃从肩部向上推举"},
  {"name":"卷腹","category":"力量","muscle_group":"腹","icon_code":"59653","description":"仰卧屈膝，上背部离地卷腹"},
  {"name":"平板支撑","category":"力量","muscle_group":"腹","icon_code":"59653","description":"俯卧，前臂和脚尖支撑身体，保持直线"},
  {"name":"哑铃耸肩","category":"力量","muscle_group":"肩","icon_code":"59652","description":"站立，双手持哑铃做耸肩动作"},
  {"name":"腿弯举","category":"力量","muscle_group":"腿","icon_code":"59649","description":"俯卧于腿弯举机，勾腿锻炼股二头肌"},
  {"name":"坐姿划船","category":"力量","muscle_group":"背","icon_code":"59650","description":"坐于划船机，双手拉把手至腹部"},
  {"name":"蝴蝶机夹胸","category":"力量","muscle_group":"胸","icon_code":"59648","description":"坐于蝴蝶机，双臂向内夹合"},
  {"name":"开合跳","category":"计时","muscle_group":"全身","icon_code":"59654","description":"站立，跳起同时手脚打开，再跳回"},
  {"name":"波比跳","category":"计时","muscle_group":"全身","icon_code":"59654","description":"站立→下蹲→俯卧撑姿势→跳回→垂直跳"},
  {"name":"高抬腿","category":"计时","muscle_group":"腿","icon_code":"59649","description":"原地跑步，膝盖尽量抬高"},
  {"name":"登山者","category":"计时","muscle_group":"全身","icon_code":"59654","description":"俯卧撑姿势，交替提膝至胸前"},
  {"name":"深蹲跳","category":"计时","muscle_group":"腿","icon_code":"59649","description":"深蹲后爆发跳起，落地缓冲"},
  {"name":"跳绳","category":"计时","muscle_group":"全身","icon_code":"59654","description":"模拟跳绳或使用跳绳，持续跳跃"},
  {"name":"战绳","category":"计时","muscle_group":"全身","icon_code":"59654","description":"双手持战绳交替上下摆动"},
  {"name":"冲刺跑","category":"计时","muscle_group":"腿","icon_code":"59649","description":"短距离全力冲刺"},
  {"name":"俯卧撑","category":"力量","muscle_group":"胸","icon_code":"59648","description":"双手撑地，身体下降至胸部接近地面再推起"},
  {"name":"仰卧起坐","category":"力量","muscle_group":"腹","icon_code":"59653","description":"仰卧屈膝，上半身完全坐起"}
]
```

- [ ] **Step 3: 注册 asset 到 pubspec.yaml**

在 `pubspec.yaml` 的 `flutter:` 段添加：

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/data/preset_exercises.json
```

- [ ] **Step 4: 验证 asset 可加载**

暂时在 `main.dart` 中写一段测试代码（后续 Task 会替换掉）：

```dart
// main.dart 临时替换内容
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final jsonStr = await rootBundle.loadString('assets/data/preset_exercises.json');
  final List<dynamic> data = json.decode(jsonStr);
  debugPrint('Loaded ${data.length} preset exercises');
  runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('Loaded ${data.length} exercises')))));
}
```

运行 `flutter run`，预期：界面显示 "Loaded 29 exercises"。

- [ ] **Step 5: Commit**

```bash
cd fitness_coach
git add assets/ lib/ pubspec.yaml
git commit -m "chore: create directory structure and preset exercise data"
```

---

## Phase 1: 数据模型 & 数据库层

### Task 1.1: Exercise 模型

**Files:**
- Create: `lib/models/exercise.dart`
- Test: `test/models/exercise_test.dart`

- [ ] **Step 1: 创建 test/models/exercise_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_coach/models/exercise.dart';

void main() {
  group('Exercise', () {
    test('fromMap creates Exercise with all fields', () {
      final map = {
        'id': 1,
        'name': '杠铃卧推',
        'category': '力量',
        'muscle_group': '胸',
        'icon_code': '59648',
        'description': '平板卧推',
        'is_preset': 1,
        'created_at': '2024-01-01',
      };

      final exercise = Exercise.fromMap(map);

      expect(exercise.id, 1);
      expect(exercise.name, '杠铃卧推');
      expect(exercise.category, '力量');
      expect(exercise.muscleGroup, '胸');
      expect(exercise.iconCode, '59648');
      expect(exercise.isPreset, true);
    });

    test('toMap converts Exercise to map correctly', () {
      final exercise = Exercise(
        id: 1,
        name: '深蹲',
        category: '力量',
        muscleGroup: '腿',
        iconCode: '12345',
        description: '杠铃深蹲',
        isPreset: false,
        createdAt: '2024-01-01',
      );

      final map = exercise.toMap();

      expect(map['id'], 1);
      expect(map['name'], '深蹲');
      expect(map['category'], '力量');
      expect(map['is_preset'], 0);
    });

    test('isPreset setter/getter works with int', () {
      final exercise = Exercise(name: '', category: '', muscleGroup: '', iconCode: '');
      exercise.isPreset = true;
      expect(exercise.isPreset, true);
      exercise.isPreset = false;
      expect(exercise.isPreset, false);
    });

    test('toString returns name', () {
      final exercise = Exercise(name: '卧推', category: '', muscleGroup: '', iconCode: '');
      expect(exercise.toString(), '卧推');
    });
  });
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
cd fitness_coach
flutter test test/models/exercise_test.dart
```
预期：FAIL — 找不到 `exercise.dart` 或 `Exercise` 类。

- [ ] **Step 3: 创建 lib/models/exercise.dart**

```dart
class Exercise {
  final int? id;
  final String name;
  final String category;      // '力量' 或 '计时'
  final String muscleGroup;
  final String iconCode;      // Flutter IconData codePoint
  final String? description;
  bool _isPreset;
  final String? createdAt;

  Exercise({
    this.id,
    required this.name,
    required this.category,
    required this.muscleGroup,
    required this.iconCode,
    this.description,
    bool isPreset = false,
    this.createdAt,
  }) : _isPreset = isPreset;

  bool get isPreset => _isPreset;
  set isPreset(bool value) => _isPreset = value;

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      muscleGroup: map['muscle_group'] as String,
      iconCode: map['icon_code'] as String,
      description: map['description'] as String?,
      isPreset: (map['is_preset'] as int?) == 1,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'muscle_group': muscleGroup,
      'icon_code': iconCode,
      'description': description,
      'is_preset': _isPreset ? 1 : 0,
      'created_at': createdAt,
    };
  }

  Exercise copyWith({
    int? id,
    String? name,
    String? category,
    String? muscleGroup,
    String? iconCode,
    String? description,
    bool? isPreset,
    String? createdAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      iconCode: iconCode ?? this.iconCode,
      description: description ?? this.description,
      isPreset: isPreset ?? _isPreset,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => name;
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
flutter test test/models/exercise_test.dart
```
预期：All tests passed。

- [ ] **Step 5: Commit**

```bash
cd fitness_coach
git add lib/models/exercise.dart test/models/exercise_test.dart
git commit -m "feat: add Exercise model with fromMap/toMap/copyWith"
```

### Task 1.2: PlanExercise 模型

**Files:**
- Create: `lib/models/plan_exercise.dart`
- Test: `test/models/plan_exercise_test.dart`

- [ ] **Step 1: 创建 test/models/plan_exercise_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_coach/models/plan_exercise.dart';

void main() {
  group('PlanExercise', () {
    test('fromMap creates PlanExercise for strength exercise', () {
      final map = {
        'id': 10,
        'plan_id': 1,
        'exercise_id': 5,
        'sort_order': 0,
        'sets': 3,
        'reps': 10,
        'work_seconds': 45,
        'rest_seconds': 60,
        'notes': '注意控制节奏',
      };

      final pe = PlanExercise.fromMap(map);

      expect(pe.id, 10);
      expect(pe.planId, 1);
      expect(pe.exerciseId, 5);
      expect(pe.sets, 3);
      expect(pe.reps, 10);
      expect(pe.workSeconds, 45);
      expect(pe.restSeconds, 60);
      expect(pe.notes, '注意控制节奏');
    });

    test('toMap excludes null id', () {
      final pe = PlanExercise(
        planId: 1,
        exerciseId: 5,
        sortOrder: 0,
        sets: 3,
        reps: 10,
        workSeconds: 45,
        restSeconds: 60,
      );

      final map = pe.toMap();

      expect(map.containsKey('id'), false);
      expect(map['plan_id'], 1);
      expect(map['sets'], 3);
    });

    test('toMap includes id when present', () {
      final pe = PlanExercise(
        id: 10,
        planId: 1,
        exerciseId: 5,
        sortOrder: 0,
        sets: 3,
        workSeconds: 30,
        restSeconds: 30,
      );

      final map = pe.toMap();
      expect(map['id'], 10);
    });
  });
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
flutter test test/models/plan_exercise_test.dart
```
预期：FAIL。

- [ ] **Step 3: 创建 lib/models/plan_exercise.dart**

```dart
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
```

- [ ] **Step 4: 运行测试验证通过**

```bash
flutter test test/models/plan_exercise_test.dart
```
预期：All tests passed。

- [ ] **Step 5: Commit**

```bash
cd fitness_coach
git add lib/models/plan_exercise.dart test/models/plan_exercise_test.dart
git commit -m "feat: add PlanExercise model"
```

### Task 1.3: TrainingPlan 模型

**Files:**
- Create: `lib/models/training_plan.dart`

- [ ] **Step 1: 创建 lib/models/training_plan.dart**

```dart
import 'plan_exercise.dart';

class TrainingPlan {
  final int? id;
  final String name;
  final String? description;
  final String? createdAt;
  final String? updatedAt;
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
```

- [ ] **Step 2: 创建快速验证测试 test/models/training_plan_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_coach/models/training_plan.dart';
import 'package:fitness_coach/models/plan_exercise.dart';

void main() {
  group('TrainingPlan', () {
    test('fromMap creates plan without exercises', () {
      final map = {
        'id': 1,
        'name': '推胸日',
        'description': '专注胸部训练',
      };
      final plan = TrainingPlan.fromMap(map);
      expect(plan.name, '推胸日');
      expect(plan.exercises, isEmpty);
    });

    test('estimatedDurationText', () {
      final plan = TrainingPlan(name: '测试');
      plan.exercises = [
        PlanExercise(planId: 1, exerciseId: 1, sortOrder: 0, sets: 3, workSeconds: 45, restSeconds: 60),
        PlanExercise(planId: 1, exerciseId: 2, sortOrder: 1, sets: 3, workSeconds: 45, restSeconds: 60),
      ];
      // 2 × 3 × (45+60) = 2 × 315 = 630s = 10.5min → "约10分钟"
      expect(plan.estimatedDurationText, '约10分钟');
    });

    test('exerciseCount', () {
      final plan = TrainingPlan(name: '测试');
      plan.exercises = [
        PlanExercise(planId: 1, exerciseId: 1, sortOrder: 0, sets: 3, workSeconds: 30, restSeconds: 30),
      ];
      expect(plan.exerciseCount, 1);
    });
  });
}
```

- [ ] **Step 3: 运行测试**

```bash
flutter test test/models/training_plan_test.dart
```
预期：All tests passed。

- [ ] **Step 4: Commit**

```bash
cd fitness_coach
git add lib/models/training_plan.dart test/models/training_plan_test.dart
git commit -m "feat: add TrainingPlan model"
```

### Task 1.4: WorkoutSession 模型

**Files:**
- Create: `lib/models/workout_session.dart`

- [ ] **Step 1: 创建 lib/models/workout_session.dart**

```dart
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
      'exercises_json': json.encode(completedExercises.map((e) => e.toJson()).toList()),
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
      return '${dt.month}月${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return startedAt;
    }
  }
}
```

- [ ] **Step 2: 创建测试 test/models/workout_session_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_coach/models/workout_session.dart';

void main() {
  group('WorkoutSession', () {
    test('fromMap with exercises_json', () {
      final map = {
        'id': 1,
        'plan_id': 1,
        'plan_name': '推胸日',
        'started_at': '2024-12-20T14:30:00',
        'finished_at': '2024-12-20T15:02:15',
        'duration_sec': 1935,
        'exercises_json': '[{"exerciseName":"卧推","plannedSets":3,"completedSets":3}]',
      };
      final session = WorkoutSession.fromMap(map);
      expect(session.planName, '推胸日');
      expect(session.durationSec, 1935);
      expect(session.formattedDuration, '32分15秒');
      expect(session.completedExercises.length, 1);
      expect(session.completedExercises.first.exerciseName, '卧推');
    });

    test('toMap serializes exercises_json', () {
      final session = WorkoutSession(
        planId: 1,
        planName: '测试',
        startedAt: '2024-01-01T00:00:00',
        durationSec: 100,
        completedExercises: [
          CompletedExercise(exerciseName: '深蹲', plannedSets: 3, completedSets: 3),
        ],
      );
      final map = session.toMap();
      expect(map['exercises_json'], contains('深蹲'));
    });
  });
}
```

- [ ] **Step 3: 运行测试**

```bash
flutter test test/models/workout_session_test.dart
```
预期：All tests passed。

- [ ] **Step 4: Commit**

```bash
cd fitness_coach
git add lib/models/workout_session.dart test/models/workout_session_test.dart
git commit -m "feat: add WorkoutSession model"
```

---

## Phase 2: 数据库层

### Task 2.1: DatabaseHelper

**Files:**
- Create: `lib/database/database_helper.dart`

- [ ] **Step 1: 创建 lib/database/database_helper.dart**

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fitness_coach.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        muscle_group TEXT NOT NULL,
        icon_code TEXT NOT NULL,
        description TEXT,
        is_preset INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE training_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE plan_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        sets INTEGER NOT NULL DEFAULT 3,
        reps INTEGER,
        work_seconds INTEGER NOT NULL DEFAULT 45,
        rest_seconds INTEGER NOT NULL DEFAULT 60,
        notes TEXT,
        FOREIGN KEY (plan_id) REFERENCES training_plans(id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL,
        plan_name TEXT NOT NULL,
        started_at TEXT NOT NULL,
        finished_at TEXT,
        duration_sec INTEGER NOT NULL DEFAULT 0,
        exercises_json TEXT NOT NULL DEFAULT '[]'
      )
    ''');
  }

  /// 仅用于测试：重置数据库
  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fitness_coach.db');
    await deleteDatabase(path);
    _database = null;
  }
}
```

- [ ] **Step 2: 创建简单测试 test/database/database_helper_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_coach/database/database_helper.dart';

void main() {
  test('DatabaseHelper is singleton', () {
    final db1 = DatabaseHelper();
    final db2 = DatabaseHelper();
    expect(identical(db1, db2), true);
  });

  test('database opens successfully', () async {
    final db = await DatabaseHelper().database;
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
    );
    final tableNames = tables.map((t) => t['name'] as String).toList();
    expect(tableNames, contains('exercises'));
    expect(tableNames, contains('training_plans'));
    expect(tableNames, contains('plan_exercises'));
    expect(tableNames, contains('workout_sessions'));
  });
}
```

- [ ] **Step 3: 运行测试**

```bash
flutter test test/database/database_helper_test.dart
```
预期：All tests passed。

- [ ] **Step 4: Commit**

```bash
cd fitness_coach
git add lib/database/database_helper.dart test/database/database_helper_test.dart
git commit -m "feat: add DatabaseHelper with 4 tables"
```

### Task 2.2: ExerciseDao

**Files:**
- Create: `lib/database/exercise_dao.dart`
- Test: `test/database/exercise_dao_test.dart`

- [ ] **Step 1: 创建 lib/database/exercise_dao.dart**

```dart
import 'package:sqflite/sqflite.dart';
import 'package:fitness_coach/database/database_helper.dart';
import 'package:fitness_coach/models/exercise.dart';

class ExerciseDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(Exercise exercise) async {
    final db = await _dbHelper.database;
    return await db.insert('exercises', exercise.toMap());
  }

  Future<List<Exercise>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('exercises', orderBy: 'category, name');
    return maps.map((m) => Exercise.fromMap(m)).toList();
  }

  Future<Exercise?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('exercises', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Exercise.fromMap(maps.first);
  }

  Future<List<Exercise>> getByCategory(String category) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'exercises',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'name',
    );
    return maps.map((m) => Exercise.fromMap(m)).toList();
  }

  Future<List<Exercise>> getCustom() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'exercises',
      where: 'is_preset = 0',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Exercise.fromMap(m)).toList();
  }

  Future<int> update(Exercise exercise) async {
    final db = await _dbHelper.database;
    return await db.update(
      'exercises',
      exercise.toMap(),
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  /// 批量插入预置动作
  Future<void> insertPresetExercises(List<Exercise> exercises) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final exercise in exercises) {
      batch.insert('exercises', exercise.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// 检查是否已有预置数据
  Future<bool> hasPresetExercises() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM exercises WHERE is_preset = 1'
    );
    return (result.first['cnt'] as int) > 0;
  }
}
```

- [ ] **Step 2: 创建测试**

```dart
// test/database/exercise_dao_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_coach/database/database_helper.dart';
import 'package:fitness_coach/database/exercise_dao.dart';
import 'package:fitness_coach/models/exercise.dart';

void main() {
  late ExerciseDao dao;

  setUp(() async {
    await DatabaseHelper().resetDatabase();
    // 重新初始化
    final db = await DatabaseHelper().database;
    dao = ExerciseDao();
  });

  test('insert and getById', () async {
    final exercise = Exercise(
      name: '测试动作',
      category: '力量',
      muscleGroup: '胸',
      iconCode: '123',
      isPreset: false,
      createdAt: DateTime.now().toIso8601String(),
    );
    final id = await dao.insert(exercise);
    expect(id, greaterThan(0));

    final fetched = await dao.getById(id);
    expect(fetched, isNotNull);
    expect(fetched!.name, '测试动作');
  });

  test('getAll returns exercises ordered', () async {
    await dao.insert(Exercise(name: 'B', category: '力量', muscleGroup: '', iconCode: '', createdAt: DateTime.now().toIso8601String()));
    await dao.insert(Exercise(name: 'A', category: '力量', muscleGroup: '', iconCode: '', createdAt: DateTime.now().toIso8601String()));
    final all = await dao.getAll();
    expect(all.length, greaterThanOrEqual(2));
    expect(all.first.name, 'A'); // 按 category, name 排序
  });

  test('delete removes exercise', () async {
    final id = await dao.insert(Exercise(name: 'X', category: '计时', muscleGroup: '', iconCode: '', createdAt: DateTime.now().toIso8601String()));
    await dao.delete(id);
    final fetched = await dao.getById(id);
    expect(fetched, isNull);
  });

  test('update modifies exercise', () async {
    final id = await dao.insert(Exercise(name: '原名称', category: '力量', muscleGroup: '胸', iconCode: '', createdAt: DateTime.now().toIso8601String()));
    final updated = Exercise(id: id, name: '新名称', category: '力量', muscleGroup: '胸', iconCode: '');
    await dao.update(updated);
    final fetched = await dao.getById(id);
    expect(fetched!.name, '新名称');
  });
}
```

- [ ] **Step 3: 运行测试**

```bash
flutter test test/database/exercise_dao_test.dart
```
预期：All tests passed（注意：每个 test 需要独立数据库状态，setUp 中 reset）。

- [ ] **Step 4: Commit**

```bash
cd fitness_coach
git add lib/database/exercise_dao.dart test/database/exercise_dao_test.dart
git commit -m "feat: add ExerciseDao with CRUD + preset import"
```

### Task 2.3: PlanDao

**Files:**
- Create: `lib/database/plan_dao.dart`

- [ ] **Step 1: 创建 lib/database/plan_dao.dart**

```dart
import 'package:sqflite/sqflite.dart';
import 'package:fitness_coach/database/database_helper.dart';
import 'package:fitness_coach/models/training_plan.dart';
import 'package:fitness_coach/models/plan_exercise.dart';

class PlanDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ─── TrainingPlan CRUD ───

  Future<int> insertPlan(TrainingPlan plan) async {
    final db = await _dbHelper.database;
    return await db.insert('training_plans', plan.toMap());
  }

  Future<List<TrainingPlan>> getAllPlans() async {
    final db = await _dbHelper.database;
    final maps = await db.query('training_plans', orderBy: 'updated_at DESC');
    final plans = maps.map((m) => TrainingPlan.fromMap(m)).toList();
    // 为每个 plan 加载 exercises
    for (final plan in plans) {
      plan.exercises = await _getPlanExercises(plan.id!);
    }
    return plans;
  }

  Future<TrainingPlan?> getPlanById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('training_plans', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final plan = TrainingPlan.fromMap(maps.first);
    plan.exercises = await _getPlanExercises(id);
    return plan;
  }

  Future<int> updatePlan(TrainingPlan plan) async {
    final db = await _dbHelper.database;
    return await db.update(
      'training_plans',
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  Future<int> deletePlan(int id) async {
    final db = await _dbHelper.database;
    // 先删关联的 plan_exercises
    await db.delete('plan_exercises', where: 'plan_id = ?', whereArgs: [id]);
    return await db.delete('training_plans', where: 'id = ?', whereArgs: [id]);
  }

  // ─── PlanExercise CRUD ───

  Future<int> insertPlanExercise(PlanExercise pe) async {
    final db = await _dbHelper.database;
    return await db.insert('plan_exercises', pe.toMap());
  }

  Future<void> updatePlanExercise(PlanExercise pe) async {
    final db = await _dbHelper.database;
    await db.update('plan_exercises', pe.toMap(), where: 'id = ?', whereArgs: [pe.id]);
  }

  Future<void> deletePlanExercise(int id) async {
    final db = await _dbHelper.database;
    await db.delete('plan_exercises', where: 'id = ?', whereArgs: [id]);
  }

  /// 替换某个计划下的全部动作（批量删除 + 批量插入）
  Future<void> replacePlanExercises(int planId, List<PlanExercise> exercises) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('plan_exercises', where: 'plan_id = ?', whereArgs: [planId]);
      for (int i = 0; i < exercises.length; i++) {
        final pe = exercises[i].copyWith(sortOrder: i);
        await txn.insert('plan_exercises', pe.toMap());
      }
    });
  }

  // ─── 内部方法 ───

  Future<List<PlanExercise>> _getPlanExercises(int planId) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT pe.*, e.name as exercise_name, e.category as exercise_category,
             e.muscle_group as exercise_muscle_group, e.icon_code as exercise_icon_code
      FROM plan_exercises pe
      JOIN exercises e ON pe.exercise_id = e.id
      WHERE pe.plan_id = ?
      ORDER BY pe.sort_order
    ''', [planId]);
    return maps.map((m) => PlanExercise.fromMap(m)).toList();
  }
}
```

- [ ] **Step 2: 创建测试 test/database/plan_dao_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_coach/database/database_helper.dart';
import 'package:fitness_coach/database/exercise_dao.dart';
import 'package:fitness_coach/database/plan_dao.dart';
import 'package:fitness_coach/models/exercise.dart';
import 'package:fitness_coach/models/training_plan.dart';
import 'package:fitness_coach/models/plan_exercise.dart';

void main() {
  late PlanDao planDao;
  late ExerciseDao exerciseDao;

  setUp(() async {
    await DatabaseHelper().resetDatabase();
    await DatabaseHelper().database; // re-init
    planDao = PlanDao();
    exerciseDao = ExerciseDao();
  });

  test('insert and get plan with exercises', () async {
    // 先创建动作
    final exId = await exerciseDao.insert(Exercise(
      name: '卧推', category: '力量', muscleGroup: '胸', iconCode: '',
      createdAt: DateTime.now().toIso8601String(),
    ));

    // 创建计划
    final planId = await planDao.insertPlan(TrainingPlan(
      name: '推胸日',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    ));

    // 添加动作到计划
    await planDao.insertPlanExercise(PlanExercise(
      planId: planId,
      exerciseId: exId,
      sortOrder: 0,
      sets: 3,
      reps: 10,
      workSeconds: 45,
      restSeconds: 60,
    ));

    // 获取并验证
    final plan = await planDao.getPlanById(planId);
    expect(plan, isNotNull);
    expect(plan!.name, '推胸日');
    expect(plan.exercises.length, 1);
    expect(plan.exercises.first.exerciseName, '卧推');
    expect(plan.exercises.first.sets, 3);
  });

  test('delete plan cascades to plan_exercises', () async {
    final exId = await exerciseDao.insert(Exercise(
      name: '深蹲', category: '力量', muscleGroup: '腿', iconCode: '',
      createdAt: DateTime.now().toIso8601String(),
    ));
    final planId = await planDao.insertPlan(TrainingPlan(
      name: '腿部日',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    ));
    await planDao.insertPlanExercise(PlanExercise(
      planId: planId, exerciseId: exId, sortOrder: 0,
      sets: 3, workSeconds: 60, restSeconds: 90,
    ));

    await planDao.deletePlan(planId);
    final deleted = await planDao.getPlanById(planId);
    expect(deleted, isNull);
  });
}
```

- [ ] **Step 3: 运行测试**

```bash
flutter test test/database/plan_dao_test.dart
```
预期：All tests passed。

- [ ] **Step 4: Commit**

```bash
cd fitness_coach
git add lib/database/plan_dao.dart test/database/plan_dao_test.dart
git commit -m "feat: add PlanDao with plan + exercise CRUD and JOIN query"
```

### Task 2.4: SessionDao

**Files:**
- Create: `lib/database/session_dao.dart`

- [ ] **Step 1: 创建 lib/database/session_dao.dart**

```dart
import 'package:fitness_coach/database/database_helper.dart';
import 'package:fitness_coach/models/workout_session.dart';

class SessionDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(WorkoutSession session) async {
    final db = await _dbHelper.database;
    return await db.insert('workout_sessions', session.toMap());
  }

  Future<List<WorkoutSession>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('workout_sessions', orderBy: 'started_at DESC');
    return maps.map((m) => WorkoutSession.fromMap(m)).toList();
  }

  Future<WorkoutSession?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('workout_sessions', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return WorkoutSession.fromMap(maps.first);
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('workout_sessions', where: 'id = ?', whereArgs: [id]);
  }

  /// 获取最近 N 次训练
  Future<List<WorkoutSession>> getRecent(int limit) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'workout_sessions',
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return maps.map((m) => WorkoutSession.fromMap(m)).toList();
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd fitness_coach
git add lib/database/session_dao.dart
git commit -m "feat: add SessionDao"
```

---

## Phase 3: 服务层

### Task 3.1: TtsService

**Files:**
- Create: `lib/services/tts_service.dart`

- [ ] **Step 1: 创建 lib/services/tts_service.dart**

```dart
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isMuted = false;
  bool _initialized = false;
  bool _available = true;

  bool get isMuted => _isMuted;
  bool get isAvailable => _available;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await _flutterTts.setLanguage('zh-CN');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _initialized = true;
      _available = true;
    } catch (e) {
      _available = false;
    }
  }

  Future<void> speak(String text) async {
    if (_isMuted || !_available) return;
    try {
      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.speak(text);
    } catch (_) {
      _available = false;
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }

  void mute() => _isMuted = true;
  void unmute() => _isMuted = false;
  void toggleMute() => _isMuted = !_isMuted;

  void dispose() {
    _flutterTts.stop();
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd fitness_coach
git add lib/services/tts_service.dart
git commit -m "feat: add TtsService with mute/availability handling"
```

### Task 3.2: HapticService

**Files:**
- Create: `lib/services/haptic_service.dart`

- [ ] **Step 1: 创建 lib/services/haptic_service.dart**

```dart
import 'package:flutter/services.dart';

class HapticService {
  bool _enabled = true;

  bool get enabled => _enabled;
  set enabled(bool value) => _enabled = value;

  void light() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  void medium() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  void heavy() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// 倒计时最后3秒每秒震动：3→light, 2→medium, 1→heavy
  void countdownBuzz(int remainingSeconds) {
    if (!_enabled) return;
    switch (remainingSeconds) {
      case 3:
        light();
        break;
      case 2:
        medium();
        break;
      case 1:
        heavy();
        break;
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd fitness_coach
git add lib/services/haptic_service.dart
git commit -m "feat: add HapticService with countdown pattern"
```

### Task 3.3: NotificationService

**Files:**
- Create: `lib/services/notification_service.dart`

- [ ] **Step 1: 创建 lib/services/notification_service.dart**

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 18, minute: 0);

  bool get reminderEnabled => _reminderEnabled;
  TimeOfDay get reminderTime => _reminderTime;

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
  }

  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    _reminderEnabled = true;
    _reminderTime = time;

    await _plugin.cancelAll();

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      0,
      '训练提醒',
      '该去健身房了！今天坚持训练，你会更强大 💪',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fitness_reminder',
          '训练提醒',
          channelDescription: '每日训练提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder() async {
    _reminderEnabled = false;
    await _plugin.cancelAll();
  }
}

// 时间相关的简单工具类（避免额外文件）
class TimeOfDay {
  final int hour;
  final int minute;
  const TimeOfDay({required this.hour, required this.minute});

  String format() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static TimeOfDay fromString(String s) {
    final parts = s.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
```

> ⚠️ 注意：`TimeOfDay` 命名会和 Flutter 自带的 `material/TimeOfDay` 冲突。后续 Task 中我们会把它合并进 `NotificationService` 或使用 Flutter 原生 `TimeOfDay`。

- [ ] **Step 2: 修改：用 Flutter 原生 TimeOfDay**

把上面的自定义 `TimeOfDay` 类删除，改为 import Flutter 的 `material` 包：

```dart
import 'package:flutter/material.dart' show TimeOfDay;
```

并去掉自定义类。

- [ ] **Step 3: Commit**

```bash
cd fitness_coach
git add lib/services/notification_service.dart
git commit -m "feat: add NotificationService with daily reminder"
```

### Task 3.4: CoachEngine（核心）

**Files:**
- Create: `lib/services/coach_engine.dart`

- [ ] **Step 1: 创建 lib/services/coach_engine.dart**

这是最大的单个文件，包含完整的教练状态机。

```dart
import 'dart:async';
import 'package:fitness_coach/models/training_plan.dart';
import 'package:fitness_coach/models/plan_exercise.dart';
import 'package:fitness_coach/services/tts_service.dart';
import 'package:fitness_coach/services/haptic_service.dart';

enum CoachPhase {
  idle,
  announcing,
  working,
  paused,
  resting,
  transitioning,
  completed,
}

class CoachState {
  final CoachPhase phase;
  final int currentExerciseIndex;
  final int currentSetIndex;
  final int totalExercises;
  final int totalSetsForCurrentExercise;
  final int remainingSeconds;
  final PlanExercise? currentExercise;
  final List<PlanExercise> exercises;
  final DateTime? startedAt;

  const CoachState({
    this.phase = CoachPhase.idle,
    this.currentExerciseIndex = 0,
    this.currentSetIndex = 0,
    this.totalExercises = 0,
    this.totalSetsForCurrentExercise = 0,
    this.remainingSeconds = 0,
    this.currentExercise,
    this.exercises = const [],
    this.startedAt,
  });

  CoachState copyWith({
    CoachPhase? phase,
    int? currentExerciseIndex,
    int? currentSetIndex,
    int? totalExercises,
    int? totalSetsForCurrentExercise,
    int? remainingSeconds,
    PlanExercise? currentExercise,
    List<PlanExercise>? exercises,
    DateTime? startedAt,
  }) {
    return CoachState(
      phase: phase ?? this.phase,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
      totalExercises: totalExercises ?? this.totalExercises,
      totalSetsForCurrentExercise: totalSetsForCurrentExercise ?? this.totalSetsForCurrentExercise,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      currentExercise: currentExercise ?? this.currentExercise,
      exercises: exercises ?? this.exercises,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  /// 整体进度 0.0 - 1.0
  double get overallProgress {
    if (totalExercises == 0) return 0;
    final completedExercises = currentExerciseIndex;
    final totalSetsForCurrent = currentExercise?.sets ?? 0;
    final completedSetsInCurrent = totalSetsForCurrent > 0
        ? currentSetIndex / totalSetsForCurrent
        : 0.0;
    return (completedExercises + completedSetsInCurrent) / totalExercises;
  }
}

class CoachEngine {
  final TtsService _tts;
  final HapticService _haptic;

  final StreamController<CoachState> _stateController =
      StreamController<CoachState>.broadcast();

  Stream<CoachState> get stateStream => _stateController.stream;

  CoachState _state = const CoachState();
  CoachState get currentState => _state;

  Timer? _timer;
  DateTime? _timerBase;
  int _frozenRemaining = 0; // 暂停时冻结的剩余秒数

  CoachEngine({required TtsService tts, required HapticService haptic})
      : _tts = tts,
        _haptic = haptic;

  void loadPlan(TrainingPlan plan) {
    _emit(_state.copyWith(
      phase: CoachPhase.idle,
      exercises: plan.exercises,
      totalExercises: plan.exerciseCount,
      currentExerciseIndex: 0,
      currentSetIndex: 0,
      remainingSeconds: 0,
    ));
  }

  void start() {
    if (_state.exercises.isEmpty) return;
    _emitState(CoachPhase.announcing, remaining: 3);
    _tts.speak(_announcementText(_state.currentExercise!));
    _startTimer(3, () => _beginWorking());
  }

  void pause() {
    if (_state.phase != CoachPhase.working && _state.phase != CoachPhase.resting) return;
    _timer?.cancel();
    _frozenRemaining = _state.remainingSeconds;
    _emit(_state.copyWith(phase: CoachPhase.paused));
    _tts.speak('暂停中');
  }

  void resume() {
    if (_state.phase != CoachPhase.paused) return;
    _emitState(_previousPhase(), remaining: _frozenRemaining);
    _startTimer(_frozenRemaining, () => _onTimerComplete());
  }

  void skipRest() {
    if (_state.phase != CoachPhase.resting) return;
    _timer?.cancel();
    _onRestComplete();
  }

  void stop() {
    _timer?.cancel();
    _emit(const CoachState(phase: CoachPhase.idle));
  }

  void dispose() {
    _timer?.cancel();
    _stateController.close();
  }

  // ─── 内部状态转换 ───

  void _emitState(CoachPhase phase, {int remaining = 0}) {
    final exercise = _state.currentExercise;
    _emit(_state.copyWith(
      phase: phase,
      remainingSeconds: remaining,
      totalSetsForCurrentExercise: exercise?.sets ?? 0,
    ));
  }

  void _emit(CoachState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  void _startTimer(int seconds, VoidCallback onDone) {
    _timerBase = DateTime.now();
    _emitState(_state.phase, remaining: seconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsed = DateTime.now().difference(_timerBase!).inSeconds;
      final remaining = seconds - elapsed;

      if (remaining <= 0) {
        timer.cancel();
        onDone();
        return;
      }

      _emitState(_state.phase, remaining: remaining);

      // 最后3秒：语音倒数 + 震动
      if (remaining <= 3) {
        _haptic.countdownBuzz(remaining);
        _tts.speak('$remaining');
      }
    });
  }

  void _beginWorking() {
    final exercise = _state.currentExercise!;
    final workTime = exercise.workSeconds;
    _emitState(CoachPhase.working, remaining: workTime);
    _startTimer(workTime, () => _onWorkComplete());
  }

  void _onWorkComplete() {
    final exercise = _state.currentExercise!;
    final newSetIndex = _state.currentSetIndex + 1;

    if (newSetIndex >= exercise.sets) {
      // 当前动作完成
      _tts.speak('${exercise.exerciseName ?? '动作'}完成');
      _beginTransitioning();
    } else {
      // 进入休息
      _emit(_state.copyWith(currentSetIndex: newSetIndex));
      _emitState(CoachPhase.resting, remaining: exercise.restSeconds);
      _startTimer(exercise.restSeconds, () => _onRestComplete());
    }
  }

  void _onRestComplete() {
    _emitState(CoachPhase.working, remaining: _state.currentExercise!.workSeconds);
    _startTimer(_state.currentExercise!.workSeconds, () => _onWorkComplete());
  }

  void _beginTransitioning() {
    final newExIndex = _state.currentExerciseIndex + 1;
    if (newExIndex >= _state.totalExercises) {
      // 训练完成
      _emitState(CoachPhase.completed);
      _haptic.heavy();
      _tts.speak('太棒了，训练完成！');
      return;
    }

    final nextExercise = _state.exercises[newExIndex];
    _emit(_state.copyWith(
      phase: CoachPhase.transitioning,
      currentExerciseIndex: newExIndex,
      currentSetIndex: 0,
      currentExercise: nextExercise,
      remainingSeconds: 2,
    ));
    _tts.speak('下一动作：${nextExercise.exerciseName ?? ''}');

    // 2秒过渡后播报 + 开始
    Future.delayed(const Duration(seconds: 2), () {
      if (_state.phase == CoachPhase.transitioning) {
        _emitState(CoachPhase.announcing, remaining: 3);
        _tts.speak(_announcementText(nextExercise));
        _startTimer(3, () {
          _emit(_state.copyWith(currentExercise: nextExercise));
          _beginWorking();
        });
      }
    });
  }

  void _onTimerComplete() {
    switch (_state.phase) {
      case CoachPhase.announcing:
        _beginWorking();
        break;
      case CoachPhase.working:
        _onWorkComplete();
        break;
      case CoachPhase.resting:
        _onRestComplete();
        break;
      default:
        break;
    }
  }

  CoachPhase _previousPhase() {
    // 恢复到暂停前的阶段
    // 简化处理：如果 frozen 值接近 work_seconds 则为 working，否则 resting
    final workTime = _state.currentExercise?.workSeconds ?? 45;
    final restTime = _state.currentExercise?.restSeconds ?? 60;
    if (_frozenRemaining >= workTime - 3 && _frozenRemaining <= workTime + 3) {
      return CoachPhase.working;
    }
    if (_frozenRemaining >= restTime - 3 && _frozenRemaining <= restTime + 3) {
      return CoachPhase.resting;
    }
    return CoachPhase.working; // fallback
  }

  String _announcementText(PlanExercise exercise) {
    final name = exercise.exerciseName ?? '动作';
    final sets = exercise.sets;
    final workSec = exercise.workSeconds;
    if (exercise.reps != null) {
      return '$name，$sets组，每组${exercise.reps}次，训练${workSec}秒';
    }
    return '$name，$sets组，每组${workSec}秒';
  }
}
```

- [ ] **Step 2: 创建测试 test/services/coach_engine_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_coach/services/coach_engine.dart';
import 'package:fitness_coach/services/tts_service.dart';
import 'package:fitness_coach/services/haptic_service.dart';
import 'package:fitness_coach/models/training_plan.dart';
import 'package:fitness_coach/models/plan_exercise.dart';

void main() {
  late CoachEngine engine;
  late TtsService tts;
  late HapticService haptic;

  setUp(() async {
    tts = TtsService();
    await tts.init();
    haptic = HapticService();
    engine = CoachEngine(tts: tts, haptic: haptic);
  });

  tearDown(() {
    engine.dispose();
  });

  test('initial state is idle', () {
    expect(engine.currentState.phase, CoachPhase.idle);
  });

  test('loadPlan sets exercises and totalExercises', () {
    final plan = TrainingPlan(name: '测试');
    plan.exercises = [
      PlanExercise(planId: 1, exerciseId: 1, sortOrder: 0, sets: 3, workSeconds: 5, restSeconds: 3, exerciseName: '动作A'),
      PlanExercise(planId: 1, exerciseId: 2, sortOrder: 1, sets: 2, workSeconds: 5, restSeconds: 3, exerciseName: '动作B'),
    ];

    engine.loadPlan(plan);
    expect(engine.currentState.totalExercises, 2);
    expect(engine.currentState.exercises.length, 2);
  });

  test('stateStream emits state changes', () async {
    final plan = TrainingPlan(name: '测试');
    plan.exercises = [
      PlanExercise(planId: 1, exerciseId: 1, sortOrder: 0, sets: 1, workSeconds: 2, restSeconds: 1, exerciseName: '快测'),
    ];

    engine.loadPlan(plan);
    engine.start();

    final states = <CoachState>[];
    final sub = engine.stateStream.listen((s) {
      states.add(s);
    });

    // 等待状态流转完成
    await Future.delayed(const Duration(seconds: 12));
    await sub.cancel();

    // 应该经历: idle → announcing → working → resting → working? → transitioning → announcing → working → completed
    expect(states.any((s) => s.phase == CoachPhase.announcing), true);
    expect(states.any((s) => s.phase == CoachPhase.working), true);
  });
}
```

- [ ] **Step 3: 运行测试**

```bash
flutter test test/services/coach_engine_test.dart
```
预期：测试通过（第二个测试需要约12秒，是正常的）。

- [ ] **Step 4: Commit**

```bash
cd fitness_coach
git add lib/services/coach_engine.dart test/services/coach_engine_test.dart
git commit -m "feat: add CoachEngine with full state machine"
```

---

## Phase 4: 状态管理层

### Task 4.1: SettingsProvider

**Files:**
- Create: `lib/providers/settings_provider.dart`

- [ ] **Step 1: 创建 lib/providers/settings_provider.dart**

```dart
import 'package:flutter/material.dart';
import 'package:fitness_coach/services/tts_service.dart';
import 'package:fitness_coach/services/haptic_service.dart';
import 'package:fitness_coach/services/notification_service.dart';

class SettingsProvider extends ChangeNotifier {
  final TtsService _tts;
  final HapticService _haptic;
  final NotificationService _notification;

  SettingsProvider({
    required TtsService tts,
    required HapticService haptic,
    required NotificationService notification,
  })  : _tts = tts,
        _haptic = haptic,
        _notification = notification;

  bool get ttsEnabled => !_tts.isMuted;
  bool get hapticEnabled => _haptic.enabled;
  bool get reminderEnabled => _notification.reminderEnabled;
  TimeOfDay get reminderTime => _notification.reminderTime;

  void toggleTts() {
    _tts.toggleMute();
    notifyListeners();
  }

  void toggleHaptic() {
    _haptic.enabled = !_haptic.enabled;
    notifyListeners();
  }

  Future<void> toggleReminder(bool enabled) async {
    if (enabled) {
      await _notification.scheduleDailyReminder(_notification.reminderTime);
    } else {
      await _notification.cancelReminder();
    }
    notifyListeners();
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    await _notification.scheduleDailyReminder(time);
    notifyListeners();
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd fitness_coach
git add lib/providers/settings_provider.dart
git commit -m "feat: add SettingsProvider"
```

### Task 4.2: PlanProvider

**Files:**
- Create: `lib/providers/plan_provider.dart`

- [ ] **Step 1: 创建 lib/providers/plan_provider.dart**

```dart
import 'package:flutter/material.dart';
import 'package:fitness_coach/database/plan_dao.dart';
import 'package:fitness_coach/models/training_plan.dart';
import 'package:fitness_coach/models/plan_exercise.dart';

class PlanProvider extends ChangeNotifier {
  final PlanDao _planDao = PlanDao();
  List<TrainingPlan> _plans = [];
  bool _loading = false;

  List<TrainingPlan> get plans => _plans;
  bool get loading => _loading;

  Future<void> loadPlans() async {
    _loading = true;
    notifyListeners();
    _plans = await _planDao.getAllPlans();
    _loading = false;
    notifyListeners();
  }

  Future<TrainingPlan?> getPlan(int id) async {
    return await _planDao.getPlanById(id);
  }

  Future<int> createPlan(TrainingPlan plan) async {
    final now = DateTime.now().toIso8601String();
    final planToSave = plan.copyWith(createdAt: now, updatedAt: now);
    final id = await _planDao.insertPlan(planToSave);
    await loadPlans();
    return id;
  }

  Future<void> updatePlan(TrainingPlan plan) async {
    plan.updatedAt = DateTime.now().toIso8601String();
    await _planDao.updatePlan(plan);
    await loadPlans();
  }

  Future<void> deletePlan(int id) async {
    await _planDao.deletePlan(id);
    await loadPlans();
  }

  Future<void> savePlanExercises(int planId, List<PlanExercise> exercises) async {
    await _planDao.replacePlanExercises(planId, exercises);
    // 更新时间戳
    final plan = await _planDao.getPlanById(planId);
    if (plan != null) {
      plan.updatedAt = DateTime.now().toIso8601String();
      await _planDao.updatePlan(plan);
    }
    await loadPlans();
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd fitness_coach
git add lib/providers/plan_provider.dart
git commit -m "feat: add PlanProvider"
```

### Task 4.3: WorkoutProvider

**Files:**
- Create: `lib/providers/workout_provider.dart`

- [ ] **Step 1: 创建 lib/providers/workout_provider.dart**

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fitness_coach/services/coach_engine.dart';
import 'package:fitness_coach/services/tts_service.dart';
import 'package:fitness_coach/services/haptic_service.dart';
import 'package:fitness_coach/models/training_plan.dart';
import 'package:fitness_coach/database/session_dao.dart';
import 'package:fitness_coach/models/workout_session.dart';

class WorkoutProvider extends ChangeNotifier {
  final CoachEngine _engine;
  final SessionDao _sessionDao = SessionDao();
  CoachState _coachState = const CoachState();
  StreamSubscription<CoachState>? _sub;
  DateTime? _workoutStartedAt;

  WorkoutProvider({required TtsService tts, required HapticService haptic})
      : _engine = CoachEngine(tts: tts, haptic: haptic) {
    _sub = _engine.stateStream.listen((state) {
      _coachState = state;
      if (state.phase == CoachPhase.completed) {
        _saveSession();
      }
      notifyListeners();
    });
  }

  CoachState get coachState => _coachState;

  void loadPlan(TrainingPlan plan) {
    _engine.loadPlan(plan);
    notifyListeners();
  }

  void startWorkout() {
    _workoutStartedAt = DateTime.now();
    _engine.start();
  }

  void pause() => _engine.pause();
  void resume() => _engine.resume();
  void skipRest() => _engine.skipRest();
  void stopWorkout() => _engine.stop();

  Future<void> _saveSession() async {
    if (_workoutStartedAt == null) return;
    final now = DateTime.now();
    final duration = now.difference(_workoutStartedAt!).inSeconds;

    final exercises = _coachState.exercises.map((e) {
      return CompletedExercise(
        exerciseName: e.exerciseName ?? '未知动作',
        plannedSets: e.sets,
        completedSets: e.sets, // MVP: 假设全部完成
      );
    }).toList();

    final session = WorkoutSession(
      planId: 0, // 可在后续关联
      planName: '',
      startedAt: _workoutStartedAt!.toIso8601String(),
      finishedAt: now.toIso8601String(),
      durationSec: duration,
      completedExercises: exercises,
    );

    await _sessionDao.insert(session);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _engine.dispose();
    super.dispose();
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd fitness_coach
git add lib/providers/workout_provider.dart
git commit -m "feat: add WorkoutProvider wrapping CoachEngine"
```

---

## Phase 5: UI — 首页 & 计划管理

### Task 5.1: App 入口 & 主题

**Files:**
- Modify: `lib/main.dart`（替换默认内容）
- Create: `lib/app.dart`

- [ ] **Step 1: 创建 lib/app.dart**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitness_coach/providers/plan_provider.dart';
import 'package:fitness_coach/providers/workout_provider.dart';
import 'package:fitness_coach/providers/settings_provider.dart';
import 'package:fitness_coach/services/tts_service.dart';
import 'package:fitness_coach/services/haptic_service.dart';
import 'package:fitness_coach/services/notification_service.dart';
import 'package:fitness_coach/pages/home_page.dart';

class FitnessCoachApp extends StatelessWidget {
  final TtsService ttsService;
  final HapticService hapticService;
  final NotificationService notificationService;

  const FitnessCoachApp({
    super.key,
    required this.ttsService,
    required this.hapticService,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlanProvider()..loadPlans()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider(tts: ttsService, haptic: hapticService)),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            tts: ttsService,
            haptic: hapticService,
            notification: notificationService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Fitness Coach',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4CAF50),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}
```

- [ ] **Step 2: 修改 lib/main.dart**

```dart
import 'package:flutter/material.dart';
import 'package:fitness_coach/app.dart';
import 'package:fitness_coach/database/database_helper.dart';
import 'package:fitness_coach/database/exercise_dao.dart';
import 'package:fitness_coach/services/tts_service.dart';
import 'package:fitness_coach/services/haptic_service.dart';
import 'package:fitness_coach/services/notification_service.dart';
import 'package:fitness_coach/models/exercise.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化数据库
  final dbHelper = DatabaseHelper();
  await dbHelper.database;

  // 导入预置动作
  final exerciseDao = ExerciseDao();
  final hasPresets = await exerciseDao.hasPresetExercises();
  if (!hasPresets) {
    final jsonStr = await rootBundle.loadString('assets/data/preset_exercises.json');
    final List<dynamic> data = json.decode(jsonStr);
    final exercises = data.map((e) => Exercise(
      name: e['name'] as String,
      category: e['category'] as String,
      muscleGroup: e['muscle_group'] as String,
      iconCode: e['icon_code'] as String,
      description: e['description'] as String?,
      isPreset: true,
      createdAt: DateTime.now().toIso8601String(),
    )).toList();
    await exerciseDao.insertPresetExercises(exercises);
  }

  // 初始化服务
  final ttsService = TtsService();
  await ttsService.init();

  final hapticService = HapticService();

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(FitnessCoachApp(
    ttsService: ttsService,
    hapticService: hapticService,
    notificationService: notificationService,
  ));
}
```

- [ ] **Step 3: 运行验证**

```bash
cd fitness_coach
flutter run
```
预期：App 启动，但 HomePage 还是占位，显示空白或在 AppBar 标题。

- [ ] **Step 4: Commit**

```bash
cd fitness_coach
git add lib/main.dart lib/app.dart
git commit -m "feat: add app entry with DB init, preset import, MultiProvider"
```

### Task 5.2: HomePage（计划列表首页）

**Files:**
- Create: `lib/pages/home_page.dart`

- [ ] **Step 1: 创建 lib/pages/home_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitness_coach/providers/plan_provider.dart';
import 'package:fitness_coach/providers/workout_provider.dart';
import 'package:fitness_coach/models/training_plan.dart';
import 'package:fitness_coach/pages/plan_edit_page.dart';
import 'package:fitness_coach/pages/workout_page.dart';
import 'package:fitness_coach/pages/history_page.dart';
import 'package:fitness_coach/pages/settings_page.dart';
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
    HistoryPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentTab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) => setState(() => _currentTab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.fitness_center), label: '计划'),
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
      appBar: AppBar(title: const Text('🏋️ Fitness Coach')),
      body: Consumer<PlanProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.plans.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('还没有训练计划', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('点击下方按钮创建第一个计划', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.plans.length,
            itemBuilder: (context, index) {
              final plan = provider.plans[index];
              return PlanCard(
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
    // 弹出确认
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(plan.name),
        content: Text('${plan.exerciseCount} 个动作 · ${plan.estimatedDurationText}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('开始训练')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final workoutProvider = context.read<WorkoutProvider>();
      workoutProvider.loadPlan(plan);
      Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutPage()));
    }
  }

  void _onEditPlan(BuildContext context, TrainingPlan plan) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlanEditPage(plan: plan)),
    );
    if (context.mounted) {
      context.read<PlanProvider>().loadPlans();
    }
  }

  void _onCreatePlan(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlanEditPage()),
    );
    if (context.mounted) {
      context.read<PlanProvider>().loadPlans();
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd fitness_coach
git add lib/pages/home_page.dart
git commit -m "feat: add HomePage with plan list, bottom nav, FAB"
```

### Task 5.3: PlanCard widget

**Files:**
- Create: `lib/widgets/plan_card.dart`

- [ ] **Step 1: 创建 lib/widgets/plan_card.dart**

```dart
import 'package:flutter/material.dart';
import 'package:fitness_coach/models/training_plan.dart';

class PlanCard extends StatelessWidget {
  final TrainingPlan plan;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const PlanCard({
    super.key,
    required this.plan,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.fitness_center, color: colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${plan.exerciseCount}个动作 · ${plan.estimatedDurationText}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd fitness_coach
git add lib/widgets/plan_card.dart
git commit -m "feat: add PlanCard widget"
```

### Task 5.4: PlanEditPage（计划编辑）& ExercisePicker

**Files:**
- Create: `lib/pages/plan_edit_page.dart`
- Create: `lib/pages/exercise_picker.dart`

- [ ] **Step 1: 创建 lib/pages/plan_edit_page.dart**

```dart
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
                Text('动作列表', style: Theme.of(context).textTheme.titleMedium),
                Text('${_exercises.length} 个动作', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 8),
            ..._exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final pe = entry.value;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.drag_handle),
                  title: Text(pe.exerciseName ?? '动作${index + 1}'),
                  subtitle: Text('${pe.sets}组 · ${pe.workSeconds}秒/组 · 休息${pe.restSeconds}秒'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      setState(() => _exercises.removeAt(index));
                    },
                  ),
                  onTap: () => _editExercise(index),
                ),
              );
            }),
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
          notes: result['notes'] as String?,
          exerciseName: result['exerciseName'] as String?,
        ));
      });
    }
  }

  void _editExercise(int index) async {
    // 简化处理：删除旧动作，重新添加
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
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
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

    // 保存动作
    final exercises = _exercises.map((e) => e.copyWith(planId: planId)).toList();
    await provider.savePlanExercises(planId, exercises);

    if (mounted) Navigator.pop(context);
  }
}
```

- [ ] **Step 2: 创建 lib/pages/exercise_picker.dart**

```dart
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

  // 参数
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
        _filtered = _exercises.where((e) => e.name.contains(query)).toList();
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
                children: categories.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(entry.key,
                          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...entry.value.map((e) => ListTile(
                        leading: Icon(_iconForCategory(e.category)),
                        title: Text(e.name),
                        subtitle: Text(e.category),
                        onTap: () {
                          setState(() {
                            _selected = e;
                            _showParams = true;
                          });
                        },
                      )),
                    ],
                  );
                }).toList(),
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
            _buildNumberField('训练时长（秒/组）', _workSeconds, (v) => _workSeconds = v),
            const SizedBox(height: 12),
            _buildNumberField('组数', _sets, (v) => _sets = v),
            const SizedBox(height: 12),
            _buildNumberField('次数（可选，力量训练）', _reps ?? 0, (v) => _reps = v > 0 ? v : null),
            const SizedBox(height: 12),
            _buildNumberField('组间休息（秒）', _restSeconds, (v) => _restSeconds = v),
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

  Widget _buildNumberField(String label, int value, Function(int) onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        SizedBox(
          width: 120,
          child: TextField(
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: value.toString()),
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            onChanged: (v) => onChanged(int.tryParse(v) ?? value),
          ),
        ),
      ],
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case '力量':
        return Icons.fitness_center;
      case '计时':
        return Icons.timer;
      default:
        return Icons.sports_gymnastics;
    }
  }
}
```

- [ ] **Step 3: Commit**

```bash
cd fitness_coach
git add lib/pages/plan_edit_page.dart lib/pages/exercise_picker.dart
git commit -m "feat: add PlanEditPage and ExercisePicker"
```

---

## Phase 6: UI — 跟练页面（核心）

### Task 6.1: 环形倒计时组件

**Files:**
- Create: `lib/widgets/countdown_ring.dart`

- [ ] **Step 1: 创建 lib/widgets/countdown_ring.dart**

```dart
import 'package:flutter/material.dart';

class CountdownRing extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final double size;

  const CountdownRing({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = totalSeconds > 0 ? remainingSeconds / totalSeconds : 0.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 12,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$remainingSeconds',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              Text(
                '秒',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd fitness_coach
git add lib/widgets/countdown_ring.dart
git commit -m "feat: add CountdownRing widget"
```

### Task 6.2: WorkoutPage（跟练核心页面）

**Files:**
- Create: `lib/pages/workout_page.dart`
- Create: `lib/pages/workout_summary_page.dart`

- [ ] **Step 1: 创建 lib/pages/workout_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitness_coach/providers/workout_provider.dart';
import 'package:fitness_coach/services/coach_engine.dart';
import 'package:fitness_coach/widgets/countdown_ring.dart';
import 'package:fitness_coach/pages/workout_summary_page.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 自动开始
    Future.microtask(() {
      context.read<WorkoutProvider>().startWorkout();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App 进入后台时不做特殊处理（计时器用时间戳差值保证精度）
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitDialog();
        if (shouldExit && mounted) {
          context.read<WorkoutProvider>().stopWorkout();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Consumer<WorkoutProvider>(
            builder: (context, provider, _) {
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

              return _buildWorkoutView(context, state);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutView(BuildContext context, CoachState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPaused = state.phase == CoachPhase.paused;

    return Column(
      children: [
        // 顶部栏
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
              if (state.phase != CoachPhase.paused && state.phase != CoachPhase.announcing && state.phase != CoachPhase.transitioning)
                IconButton(
                  icon: const Icon(Icons.pause_circle_filled, size: 32),
                  onPressed: () => context.read<WorkoutProvider>().pause(),
                ),
            ],
          ),
        ),

        const Spacer(),

        // 核心区域
        if (isPaused)
          _buildPausedView(context)
        else
          _buildActiveView(context, state),

        const Spacer(),

        // 底部信息
        if (!isPaused) _buildBottomInfo(context, state),

        const SizedBox(height: 24),
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
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
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

    if (phase == CoachPhase.working || phase == CoachPhase.resting) {
      final isWorking = phase == CoachPhase.working;
      final total = isWorking
          ? (state.currentExercise?.workSeconds ?? 45)
          : (state.currentExercise?.restSeconds ?? 60);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CountdownRing(
            remainingSeconds: state.remainingSeconds,
            totalSeconds: total,
            size: 200,
          ),
          const SizedBox(height: 24),
          Text(
            state.currentExercise?.exerciseName ?? '',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isWorking
                ? '第 ${state.currentSetIndex + 1} / ${state.totalSetsForCurrentExercise} 组'
                : '休息中...',
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
        const Icon(Icons.pause_circle_outline, size: 80, color: Colors.grey),
        const SizedBox(height: 16),
        const Text('暂停中', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
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
    final prevExercise = currentIdx > 0 ? exercises[currentIdx - 1] : null;
    final nextExercise = currentIdx < exercises.length - 1 ? exercises[currentIdx + 1] : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${currentIdx + 1} / ${state.totalExercises} 动作',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 8),
          // 上一动作
          if (prevExercise != null)
            Text('上一动作：${prevExercise.exerciseName} ✓',
              style: TextStyle(color: Colors.grey[500])),
          // 下一动作
          if (nextExercise != null)
            Text('下一动作：${nextExercise.exerciseName}',
              style: TextStyle(color: Colors.grey[500])),
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('继续训练')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('结束', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
```

- [ ] **Step 2: 创建 lib/pages/workout_summary_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:fitness_coach/services/coach_engine.dart';

class WorkoutSummaryPage extends StatelessWidget {
  final CoachState state;

  const WorkoutSummaryPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final totalSeconds = state.exercises.fold<int>(
      0, (sum, e) => sum + e.workSeconds * e.sets + e.restSeconds * (e.sets - 1),
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
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(_formatDuration(totalSeconds),
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                        const Text('总时长'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ...state.exercises.map((e) => ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(e.exerciseName ?? ''),
                  subtitle: Text('${e.sets}组完成'),
                )),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
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
```

- [ ] **Step 3: Commit**

```bash
cd fitness_coach
git add lib/pages/workout_page.dart lib/pages/workout_summary_page.dart
git commit -m "feat: add WorkoutPage with pause/skip and SummaryPage"
```

---

## Phase 7: UI — 历史记录 & 设置

### Task 7.1: HistoryPage

**Files:**
- Create: `lib/pages/history_page.dart`
- Create: `lib/pages/history_detail_page.dart`

- [ ] **Step 1: 创建 lib/pages/history_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:fitness_coach/database/session_dao.dart';
import 'package:fitness_coach/models/workout_session.dart';
import 'package:fitness_coach/pages/history_detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final SessionDao _dao = SessionDao();
  List<WorkoutSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await _dao.getAll();
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('训练历史')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('还没有训练记录', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      SizedBox(height: 8),
                      Text('去完成第一次训练吧！', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                        title: Text(session.planName),
                        subtitle: Text('${session.formattedDate} · ${session.completedExercises.length}动作 · ${session.formattedDuration}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HistoryDetailPage(session: session),
                            ),
                          );
                          _loadSessions();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
```

- [ ] **Step 2: 创建 lib/pages/history_detail_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:fitness_coach/database/session_dao.dart';
import 'package:fitness_coach/models/workout_session.dart';

class HistoryDetailPage extends StatelessWidget {
  final WorkoutSession session;

  const HistoryDetailPage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('训练详情'), actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('删除记录'),
                content: const Text('确定删除这条训练记录吗？'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('删除', style: TextStyle(color: Colors.red)),
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
      ]),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(session.planName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(session.formattedDate, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 4),
            Text('总时长：${session.formattedDuration}',
              style: TextStyle(color: Colors.grey[600])),
            const Divider(height: 32),
            ...session.completedExercises.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text('${e.exerciseName}  ${e.completedSets}/${e.plannedSets}组'),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
cd fitness_coach
git add lib/pages/history_page.dart lib/pages/history_detail_page.dart
git commit -m "feat: add HistoryPage and HistoryDetailPage"
```

### Task 7.2: SettingsPage

**Files:**
- Create: `lib/pages/settings_page.dart`

- [ ] **Step 1: 创建 lib/pages/settings_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitness_coach/providers/settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle(context, '通知'),
              SwitchListTile(
                title: const Text('训练提醒'),
                subtitle: settings.reminderEnabled
                    ? Text('每天 ${settings.reminderTime.format(context)}')
                    : const Text('关闭'),
                value: settings.reminderEnabled,
                onChanged: (v) => settings.toggleReminder(v),
              ),
              if (settings.reminderEnabled)
                ListTile(
                  title: const Text('提醒时间'),
                  trailing: Text(settings.reminderTime.format(context)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: settings.reminderTime,
                    );
                    if (time != null) {
                      await settings.setReminderTime(time);
                    }
                  },
                ),
              const Divider(),
              _buildSectionTitle(context, '教练'),
              SwitchListTile(
                title: const Text('语音播报'),
                value: settings.ttsEnabled,
                onChanged: (_) => settings.toggleTts(),
              ),
              SwitchListTile(
                title: const Text('震动反馈'),
                value: settings.hapticEnabled,
                onChanged: (_) => settings.toggleHaptic(),
              ),
              const Divider(),
              _buildSectionTitle(context, '关于'),
              const ListTile(title: Text('版本'), trailing: Text('v1.1.1')),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd fitness_coach
git add lib/pages/settings_page.dart
git commit -m "feat: add SettingsPage with reminder/tts/haptic toggles"
```

---

## Phase 8: 集成 & 润色

### Task 8.1: 运行全部测试 & 修复

- [ ] **Step 1: 运行全部测试**

```bash
cd fitness_coach
flutter test
```
预期：所有测试通过。如有失败，根据错误信息修复。

- [ ] **Step 2: 修复已知问题**

常见可能问题：
- `NotificationService` 中导入了 Flutter 的 `TimeOfDay`，确保 import 路径正确
- `WorkoutProvider._saveSession()` 中 `planName` 为空字符串，应在 `loadPlan` 时赋值
- `CoachEngine._previousPhase()` 逻辑可能不准确，简化为始终恢复 `working`

修复 `WorkoutProvider`：在 `loadPlan` 中保存 plan name：

```dart
String? _planName;

void loadPlan(TrainingPlan plan) {
  _planName = plan.name;
  _engine.loadPlan(plan);
  notifyListeners();
}
```

并在 `_saveSession` 中使用 `_planName`。

### Task 8.2: 最终验证 & 提交

- [ ] **Step 1: 真机运行验证**

```bash
cd fitness_coach
flutter run
```

执行以下完整流程：
1. App 首次启动，看到空计划列表
2. 创建计划「推胸日」，添加 3 个动作
3. 点击计划卡片 → 确认 → 进入跟练
4. 观察计时器自动倒计时、环形进度条、页面自动跳转
5. 测试暂停/恢复
6. 完成训练，查看总结页
7. 历史页查看记录，进入详情
8. 设置页开关语音/震动

- [ ] **Step 2: Commit**

```bash
cd fitness_coach
git add -A
git commit -m "feat: complete MVP v1.0 - Fitness Coach App"
```

---

## 附录：文件清单

```
lib/
├── main.dart
├── app.dart
├── models/
│   ├── exercise.dart
│   ├── plan_exercise.dart
│   ├── training_plan.dart
│   └── workout_session.dart
├── database/
│   ├── database_helper.dart
│   ├── exercise_dao.dart
│   ├── plan_dao.dart
│   └── session_dao.dart
├── services/
│   ├── coach_engine.dart
│   ├── tts_service.dart
│   ├── haptic_service.dart
│   └── notification_service.dart
├── providers/
│   ├── plan_provider.dart
│   ├── workout_provider.dart
│   └── settings_provider.dart
├── pages/
│   ├── home_page.dart
│   ├── plan_edit_page.dart
│   ├── exercise_picker.dart
│   ├── workout_page.dart
│   ├── workout_summary_page.dart
│   ├── history_page.dart
│   ├── history_detail_page.dart
│   └── settings_page.dart
├── widgets/
│   ├── plan_card.dart
│   └── countdown_ring.dart
assets/
└── data/
    └── preset_exercises.json
test/
├── models/
│   ├── exercise_test.dart
│   ├── plan_exercise_test.dart
│   ├── training_plan_test.dart
│   └── workout_session_test.dart
├── database/
│   ├── database_helper_test.dart
│   ├── exercise_dao_test.dart
│   └── plan_dao_test.dart
└── services/
    └── coach_engine_test.dart
```

**总计：26 个源文件 + 10 个测试文件**
