# Fitness Coach App — 产品设计文档

> **版本：** v1.2
> **创建日期：** 2024-12-22
> **最后更新：** 2026-06-22
> **状态：** 已实现，持续迭代

---

## 一、产品概述

**定位：** 跟我练 — 一个健身动作编排和跟练 App。面向有一定健身基础、知道自己该练什么、会自己编排动作，但希望有个声音在耳边指导、伴随锻炼的使用者。

**核心功能：**
1. 动作编排：用户自定义动作 + 7 个基础预置动作，按肌群分组，支持搜索
2. 训练计划：拖拽排序，自定义组数/次数/时长/组间休息/动作后休息
3. 语音跟练：TTS 播报动作信息、倒数、间隔提醒，beep 提示音，震动反馈
4. 训练记录：完成/中断均记录，详情展示每组完成状态

**平台：** Android + iOS + macOS，Flutter 跨平台，100% 离线

---

## 二、技术方案

| 维度 | 选择 |
|------|------|
| 框架 | Flutter 3.x（Dart 3.x） |
| 状态管理 | Provider |
| 本地存储 | sqflite（SQLite） |
| 语音 | flutter_tts（离线 TTS） |
| 震动 | HapticFeedback（Flutter 内置） |
| 提示音 | Android AudioTrack PCM / iOS AudioServices / macOS WAV |
| 后台保活 | iOS 静默音频 / Android 前台 Service |
| 通知 | flutter_local_notifications |
| 网络 | 无，100% 离线 |
| 账号 | 无，纯本地 |

---

## 三、架构

```
┌─────────────────────────────────────────────────────────┐
│                    Fitness Coach App                     │
├─────────────────────────────────────────────────────────┤
│  UI Layer                                               │
│  ┌────────┬──────────┬──────────┬────────────────────┐  │
│  │ 计划列表│ 动作管理  │ 训练历史  │ 设置（语音/震动/提醒）│  │
│  └────────┴──────────┴──────────┴────────────────────┘  │
├─────────────────────────────────────────────────────────┤
│  State (Provider)                                       │
│  ┌──────────────┬──────────────────┬─────────────────┐  │
│  │ PlanProvider │ WorkoutProvider  │ SettingsProvider │  │
│  └──────────────┴──────────────────┴─────────────────┘  │
├─────────────────────────────────────────────────────────┤
│  Services                                               │
│  ┌──────────┬─────────┬─────────┬────────┬───────────┐  │
│  │ Coach    │ TTS     │ Haptic  │ Beep   │ Background│  │
│  │ Engine   │ Service │ Service │ Utils  │ Service   │  │
│  └──────────┴─────────┴─────────┴────────┴───────────┘  │
├─────────────────────────────────────────────────────────┤
│  Data Layer (sqflite)                                   │
│  ┌──────────┬───────────┬───────────────┐              │
│  │ Exercise │ Training  │ Workout       │              │
│  │   表     │  Plan表   │ Session表     │              │
│  └──────────┴───────────┴───────────────┘              │
└─────────────────────────────────────────────────────────┘
```

---

## 四、页面结构 & 导航

**底部导航（4 个 Tab，IndexedStack）：** 计划 / 动作 / 历史 / 设置

| 页面 | 职责 |
|------|------|
| 计划列表（首页） | 训练计划卡片列表，拖拽排序，快速开始跟练 |
| 动作管理 | 搜索、编辑、删除自定义动作、新增，按肌群分组 |
| 历史记录 | 过往训练记录，完成 ✅ / 中断 ⭕，详情含每组完成状态 |
| 设置 | 语音、震动、间隔提醒、快捷暂停开关 |
| 计划编辑 | 创建/编辑训练计划，拖拽排序动作，5 项参数配置 |
| 跟练 | 环形倒计时（三色）+ 完整动作列表 + 进度条 |
| 训练总结 | 训练统计摘要，自动跳转 |

导航方式：`Navigator.push` / `pushReplacement` + `MaterialPageRoute`

---

## 五、数据模型

### 5.1 数据库表

**exercises（动作库）** — 7 个预置 + 用户自定义

| 列 | 类型 | 说明 |
|----|------|------|
| id | INTEGER PK | |
| name | TEXT | |
| category | TEXT | 力量 / 计时 |
| muscle_group | TEXT | 胸、腿、背、手臂、肩、腹、全身 |
| icon_code | TEXT | Flutter Icon codePoint |
| description | TEXT | |
| is_preset | INTEGER | 1=预置 0=自定义 |
| sort_order | INTEGER | |
| created_at | TEXT | |

**plan_exercises（计划中的动作）**

| 列 | 类型 | 说明 |
|----|------|------|
| id | INTEGER PK | |
| plan_id / exercise_id | INTEGER FK | |
| sort_order | INTEGER | |
| sets | INTEGER | 组数 |
| reps | INTEGER | 次数（力量型用，计时型 NULL） |
| work_seconds | INTEGER | 每组训练时长 |
| rest_seconds | INTEGER | 组间休息秒数 |
| after_rest_seconds | INTEGER | 动作完成后一次性休息秒数（v1.2 新增） |
| notes | TEXT | |

**workout_sessions（训练记录）**

| 列 | 类型 | 说明 |
|----|------|------|
| id | INTEGER PK | |
| plan_name | TEXT | 冗余快照 |
| started_at | TEXT | |
| finished_at | TEXT | null = 中断未完成 |
| duration_sec | INTEGER | |
| exercises_json | TEXT | JSON 快照：plannedSets / completedSets |

### 5.2 预置动作

首次启动插入 **7 个**基础动作，每种肌群一个：杠铃卧推（胸）、杠铃深蹲（腿）、硬拉（背）、哑铃弯举（手臂）、杠铃肩推（肩）、卷腹（腹）、开合跳（全身·计时）。其余动作由用户自行创建。

---

## 六、CoachEngine

### 6.1 状态机

```
IDLE → WORKING (先出界面再播语音)
  WORKING 倒数 → 还有组 → RESTING (组间休息, 橙色环)
               → 最后组 → afterRestSeconds>0 ? postExerciseResting (绿色环)
                                            : TRANSITIONING (2s)
  RESTING → _onRestComplete → WORKING
  postExerciseResting → _enterTransitioning → WORKING (下一动作)
  ↕ PAUSED (working/resting/postExerciseResting 均可暂停)
  COMPLETED → 总结页
```

### 6.2 状态行为矩阵

| 状态 | 语音 | 界面 | 震动 |
|------|------|------|------|
| WORKING | "动作名，开始" → 1s → beep → 倒数 | 🔴 红色环 + 组号 | 最后 3 秒 |
| RESTING | "休息N秒" → 1s → beep → 倒数 | 🟠 橙色环 + ⏭跳过 | 最后 3 秒 |
| postExerciseResting | "XX完成。下一动作：YY" → 1s → beep → 倒数 | 🟢 绿色环 + ⏭跳过 | 最后 3 秒 |
| PAUSED | "暂停中" | 冻结计时器 + ▶恢复 ⏹结束 | - |
| TRANSITIONING | "下一动作：XX" | 进度条 (N/M 动作) | - |
| COMPLETED | "太棒了，训练完成！" | 自动跳转总结页 | 长震 |

### 6.3 核心接口

```dart
class CoachEngine {
  void loadPlan(TrainingPlan plan);
  void start();
  void pause();
  void resume();
  void skipRest();
  void stop();
  Stream<CoachState> get stateStream;
}
```

### 6.4 设计要点

- **界面优先：** WORKING 状态立即显示倒计时环，再播语音
- **计时精度：** `DateTime.now() - _timerBase`，不依赖 Timer 绝对精度
- **TTS：** `awaitSpeakCompletion(true)` 一次性设置，串行排队不叠音
- **倒数防丢：** 每秒 `stop()` + `speak()`，避免 Android TTS 掉音
- **引擎预热：** `init()` 后 `speak('来，一起锻炼吧')` 预加载语音数据
- **后台保活：** iOS 静默音频 + Android 前台 Service
- **跳过休息：** `_timerOnDone` 回调解耦，组间休息和动作后休息各自正确跳转
- **异步安全：** 每次 `await` 后检查 `_state.phase`，防止 skip/stop 后的过期流程覆盖新状态
- **中断记录：** 停止训练时保存已完成组数，`finishedAt = null` 标识未完成

---

## 七、UI 关键设计

### 7.1 首页
- 计划卡片列表（名称、动作数、预计时长），`PlanCard` + 拖拽手柄
- `ReorderableListView` + `buildDefaultDragHandles: false`
- 空状态："编排你的训练 / 点击下方按钮，开始编排训练计划"

### 7.2 动作管理
- 按肌群分组（`ExpansionTile` 默认展开），搜索过滤
- 预置动作不可删除，自定义动作可编辑/删除
- FAB 创建自定义动作（弹窗输入名称、肌群、类型）

### 7.3 计划编辑
- 动作列表副标题：`{sets}组 · {workSeconds}秒/组 · 组休{restSeconds}秒 · 动休{afterRestSeconds}秒`
- 添加动作：`ExercisePicker` → 搜索/浏览 → 选择 → 5 项参数设置 → 确认

### 7.4 ExercisePicker
- 按肌群分组默认展开，搜索框 + 最近 5 条搜索历史
- 自定义动作入口可现场创建
- 参数设置页 5 个字段：训练时长、组数、次数、组间休息、动作完成后休息

### 7.5 跟练页
- 三色环形倒计时：🔴红(work) / 🟠橙(between-set rest) / 🟢绿(post-exercise rest)
- 底部完整动作列表：✅完成 ●当前 ○待做，每行显示动作名+组数
- 暂停按钮在所有倒计时阶段可见（含动作后休息）

### 7.6 训练历史
- 列表：完成 🟢 `check_circle` / 中断 🟠 `cancel_outlined` + "(未完成)"
- 详情：每组 `completedSets/plannedSets`，完成 🟢 未完成 🟠 警告

### 7.7 设置
- 教练：语音播报、震动反馈、间隔提醒（0/5/10/15/20/30s）
- 界面：快捷暂停
- 关于：版本号

---

## 八、项目文件结构

```
lib/
├── main.dart
├── app.dart
├── models/
│   ├── exercise.dart
│   ├── training_plan.dart
│   ├── plan_exercise.dart
│   └── workout_session.dart
├── database/
│   ├── database_helper.dart (version 4)
│   ├── exercise_dao.dart
│   ├── plan_dao.dart
│   └── session_dao.dart
├── services/
│   ├── coach_engine.dart
│   ├── tts_service.dart
│   ├── haptic_service.dart
│   ├── notification_service.dart
│   └── background_service_manager.dart
├── providers/
│   ├── plan_provider.dart
│   ├── workout_provider.dart
│   └── settings_provider.dart
├── pages/
│   ├── home_page.dart
│   ├── exercise_manage_page.dart
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
└── utils/
    └── beep.dart
```

---

## 九、v1.2 已实现

- 7 个预置基础动作（每肌群一个），用户自行创建其余动作
- 训练计划 CRUD + 拖拽排序 + 5 项参数配置
- 完整跟练：三色倒计时环 + 动作列表 + 进度条 + 暂停/跳过/快捷暂停
- 动作完成后一次性休息（`afterRestSeconds`）
- 三端 beep 提示音（Android AudioTrack / iOS AudioServices / macOS WAV）
- 训练后台保活（iOS 静默音频 / Android 前台 Service）
- 完成/中断训练均记录，详情展示每组完成状态
- TTS 引擎预热、倒数防丢、异步安全守卫
- 设置：语音/震动/间隔提醒/快捷暂停
- 100% 离线
