# Fitness Coach App — 产品设计文档

> **版本：** v1.0 MVP
> **创建日期：** 2024-12-22
> **状态：** 已确认

---

## 一、产品概述

**定位：** 健身跟练 App，提供一位虚拟教练，引导用户在健身房完成训练。

**核心功能：**
1. 制定训练计划（力量训练 + HIIT 计时训练）
2. 跟练模式（虚拟教练通过语音 + 界面 + 震动引导）

**目标用户：** 有健身习惯、需要一个简洁跟练工具的健身爱好者

**平台：** Android + iOS，Flutter 跨平台

---

## 二、技术方案

| 维度 | 选择 |
|------|------|
| 框架 | Flutter 3.x（Dart 3.x） |
| 状态管理 | Provider |
| 本地存储 | sqflite（SQLite） |
| 语音 | flutter_tts（离线 TTS） |
| 震动 | HapticFeedback（Flutter 内置） |
| 通知 | flutter_local_notifications |
| 网络 | 无，100% 离线 |
| 账号 | 无，纯本地 |

---

## 三、架构

```
┌─────────────────────────────────────────────────┐
│                  Fitness Coach App               │
├─────────────────────────────────────────────────┤
│  UI Layer (Flutter Widgets)                      │
│  ┌──────────┬──────────┬──────────┬──────────┐  │
│  │ 计划列表  │ 计划编辑  │ 跟练页面  │ 历史/设置 │  │
│  └──────────┴──────────┴──────────┴──────────┘  │
├─────────────────────────────────────────────────┤
│  State (Provider)                                │
│  ┌─────────────┬──────────────┬───────────────┐  │
│  │ WorkoutState│ TrainingPlan │ SettingsStore  │  │
│  └─────────────┴──────────────┴───────────────┘  │
├─────────────────────────────────────────────────┤
│  Services                                        │
│  ┌──────────┬──────────┬──────────┬──────────┐  │
│  │ Coach    │ TTS引擎   │ 震动服务  │ 通知服务  │  │
│  │ Engine   │          │          │          │  │
│  └──────────┴──────────┴──────────┴──────────┘  │
├─────────────────────────────────────────────────┤
│  Data Layer (sqflite)                            │
│  ┌──────────┬──────────┬──────────┬──────────┐  │
│  │ Exercise │ Training │ Workout  │ Settings │  │
│  │   表      │  Plan表  │ Session表│   表     │  │
│  └──────────┴──────────┴──────────┴──────────┘  │
└─────────────────────────────────────────────────┘
```

---

## 四、页面结构 & 导航

**5 个主页面：**

| 页面 | 路由 | 职责 |
|------|------|------|
| 计划列表（首页） | `/` | 展示所有训练计划，快速开始跟练 |
| 计划编辑 | `/plan/edit` | 创建/编辑训练计划 |
| 跟练 | `/workout` | 🔥核心：虚拟教练引导界面 |
| 训练总结 | `/workout/summary` | 训练完成后的统计摘要 |
| 历史记录 | `/history` | 过往训练记录列表 |
| 设置 | `/settings` | 提醒、语音、震动开关 |

**底部导航：** 计划 / 历史 / 设置

---

## 五、数据模型

### 5.1 数据库表

**exercises（动作库）**

| 列 | 类型 | 说明 |
|----|------|------|
| id | INTEGER PK | |
| name | TEXT | 卧推、深蹲... |
| category | TEXT | 力量 / 计时 |
| muscle_group | TEXT | 胸、背、腿... |
| icon_code | TEXT | Flutter Icon codePoint |
| description | TEXT | 简短动作说明 |
| is_preset | INTEGER | 1=预置 0=自定义 |
| created_at | TEXT | |

**training_plans（训练计划）**

| 列 | 类型 | 说明 |
|----|------|------|
| id | INTEGER PK | |
| name | TEXT | 推胸日、拉背日... |
| description | TEXT | |
| created_at | TEXT | |
| updated_at | TEXT | |

**plan_exercises（计划中的动作）**

| 列 | 类型 | 说明 |
|----|------|------|
| id | INTEGER PK | |
| plan_id | INTEGER FK | |
| exercise_id | INTEGER FK | |
| sort_order | INTEGER | 排序序号 |
| sets | INTEGER | 组数 |
| reps | INTEGER | 每组次数（力量型用，计时型 NULL） |
| work_seconds | INTEGER | 每组训练时长（必填） |
| rest_seconds | INTEGER | 组间休息秒数 |
| notes | TEXT | |

**workout_sessions（训练记录）**

| 列 | 类型 | 说明 |
|----|------|------|
| id | INTEGER PK | |
| plan_id | INTEGER FK | |
| plan_name | TEXT | 冗余快照 |
| started_at | TEXT | |
| finished_at | TEXT | |
| duration_sec | INTEGER | 总时长 |
| exercises_json | TEXT | JSON 快照，存完成详情 |

### 5.2 预置动作

首次启动插入 ~30 个常见动作：
- **力量类：** 卧推、上斜卧推、哑铃飞鸟、杠铃深蹲、腿举、硬拉、引体向上、杠铃划船、哑铃弯举、三头下压、侧平举、肩推、卷腹、平板支撑...
- **计时类：** 开合跳、波比跳、高抬腿、登山者、深蹲跳、跳绳、战绳、冲刺跑...

---

## 六、虚拟教练引擎（CoachEngine）

### 6.1 状态机

```
IDLE → ANNOUNCING(3s) → WORKING(倒计时) → RESTING(休息倒计时)
                          ↕ PAUSED          ↕ PAUSED
                           
RESTING → 还有组 → WORKING
       → 没组   → TRANSITIONING(2s) → 还有动作 → ANNOUNCING
                                     → 没动作   → COMPLETED → 总结页
```

### 6.2 状态行为矩阵

| 状态 | 语音 | 界面 | 震动 |
|------|------|------|------|
| ANNOUNCING | 播报动作名+参数 | 大字动作名 + 组次信息 | - |
| WORKING | 最后3秒倒数"3、2、1" | 大字倒计时 + 环形进度条 + 组号 + ⏸暂停 | 最后3秒震动 |
| PAUSED | "暂停中" | 冻结计时器 + ▶恢复 ⏹结束 | - |
| RESTING | 最后3秒倒数 | 休息倒计时 + ⏭跳过 + ⏸暂停 | 最后3秒震动 |
| TRANSITIONING | "完成！下一动作" | 进度条 (N/M 动作完成) | - |
| COMPLETED | "太棒了，训练完成！" | 统计摘要 → 自动跳转总结页 | 长震 |

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

- **计时自动流转：** WORKING 倒计时到 0 自动进入 RESTING，RESTING 到 0 自动判断是否进入下一组/下一动作。无需手动点"完成"
- **暂停通用：** WORKING 和 RESTING 中均可暂停
- **TTS 播报队列：** 顺序播报，不并发，避免叠音
- **计时精度：** 用时间戳差值计算，不依赖 Timer 绝对精度（防止 iOS 后台挂起）
- **跳过休息：** 用户可主动 skip 休息时间

---

## 七、UI 关键设计

### 7.1 首页
- 计划卡片列表（名称、动作数、预计时长）
- 点击确认后进入跟练
- 长按编辑/删除
- 空状态引导创建

### 7.2 计划编辑
- 计划名称/描述
- 动作列表（拖拽排序、点击编辑参数）
- 添加动作：弹出动作选择器 → 设置参数（时长/组数/次数/休息）→ 确认添加

### 7.3 跟练页（核心）
- 环形倒计时（大字秒数）
- 当前动作名 + 组号
- 整体进度条
- 暂停/跳过按钮
- TTS 开关指示

### 7.4 训练总结
- 总时长
- 每个动作完成状态
- 返回首页

### 7.5 历史记录
- 按日期倒序列表
- 点击查看详情
- 支持删除

### 7.6 设置
- 训练提醒开关 + 时间
- 语音/震动/倒数提示音开关

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
└── widgets/
    ├── plan_card.dart
    ├── countdown_ring.dart
    ├── progress_bar.dart
    └── exercise_tile.dart
```

约 20-25 个 Dart 文件，每个 100-200 行。

---

## 九、依赖清单

```yaml
dependencies:
  sqflite: ^2.3.0
  path: ^1.8.0
  provider: ^6.1.0
  flutter_tts: ^4.0.0
  flutter_local_notifications: ^17.0.0
  intl: ^0.19.0
  uuid: ^4.2.0
```

---

## 十、MVP 范围

### ✅ v1.0 包含
- 预置动作库 + 自定义动作
- 训练计划 CRUD + 拖拽排序
- 完整跟练教练（状态机 + TTS + 震动 + 暂停）
- 训练总结
- 历史记录
- 设置页面
- 100% 离线

### ❌ v1.0 不包含
- 用户账号 / 云同步
- 动作图片 / GIF
- 力量增长图表
- 深色模式
- 国际化
- Apple Watch 联动

---

## 十一、风险与对策

| 风险 | 对策 |
|------|------|
| 部分 Android 机型 TTS 中文不可用 | 优雅降级：检测后提示，纯界面引导可用 |
| iOS 后台计时器挂起 | 用时间戳差值，不依赖 Timer 绝对精度 |
| 初学者 Dart 学习曲线 | 前 3 天只学核心语法，边做边学 |
