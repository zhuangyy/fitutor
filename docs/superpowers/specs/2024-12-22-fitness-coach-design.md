# Fitness Coach App — 产品设计文档

> **版本：** v1.1
> **创建日期：** 2024-12-22
> **最后更新：** 2026-06-19
> **状态：** 已实现，持续迭代

---

## 一、产品概述

**定位：** 健身跟练 App（跟我练），提供一位虚拟教练，引导用户在健身房完成训练。

**核心功能：**
1. 制定训练计划（力量训练 + 计时训练），支持拖拽排序
2. 跟练模式（虚拟教练通过语音 + 界面 + 震动 + 提示音引导）
3. 动作库管理（49 个预置动作 + 自定义动作，支持搜索和分类浏览）

**目标用户：** 有健身习惯、需要一个简洁跟练工具的健身爱好者

**平台：** Android + iOS + macOS，Flutter 跨平台

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

**7 个核心页面：**

| 页面 | 职责 |
|------|------|
| 计划列表（首页） | 训练计划卡片列表，拖拽排序，快速开始跟练 |
| 动作管理 | 🔥动作库管理：搜索、编辑、删除自定义动作、新增自定义动作，按肌群分组 |
| 历史记录 | 过往训练记录列表，按日期倒序 |
| 设置 | 语音、震动、间隔提醒、快捷暂停开关 |
| 计划编辑 | 创建/编辑训练计划，拖拽排序动作，配置组数/次数/时长 |
| 跟练 | 🔥核心：虚拟教练引导界面 |
| 训练总结 | 训练完成后的统计摘要 |

**底部导航（4 个 Tab，IndexedStack）：** 计划 / 动作管理 / 历史 / 设置

导航方式：所有页面通过 `Navigator.push` / `pushReplacement` + `MaterialPageRoute` 跳转，无语义路由，无 deep linking。

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

首次启动插入 **49 个**常见动作，从 `assets/data/preset_exercises.json` 加载，`is_preset = 1` 标记。后续版本通过增量同步更新预置库。

- **力量类（~25 个）：** 卧推、上斜卧推、下斜卧推、哑铃卧推、哑铃飞鸟、杠铃深蹲、哑铃深蹲、保加利亚分腿蹲、腿举、腿弯举、直腿硬拉、传统硬拉、引体向上、高位下拉、杠铃划船、哑铃划船、坐姿划船、面拉、杠铃弯举、哑铃弯举、锤式弯举、三头绳索下压、窄距卧推、侧平举、哑铃肩推、杠铃肩推、卷腹、悬垂举腿、平板支撑…
- **计时类（~24 个）：** 开合跳、波比跳、高抬腿、登山者、深蹲跳、弓步跳、胯下击掌、滑雪跳、战绳、跳绳、冲刺跑、壶铃摇摆、药球砸墙、熊爬、俯身登山、平板支撑交替触肩、波比跳无俯卧撑、开合跳+深蹲组合、哑铃抓举、壶铃高翻、TRX划船、有氧搏击、爬楼梯、椭圆机…
- 预置动作不可删除，可编辑参数；用户自定义动作可删除

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
- **暂停通用：** WORKING 和 RESTING 中均可暂停。支持**快捷暂停**：训练/休息时点击屏幕任意位置暂停（可在设置中开关）
- **TTS 播报队列：** 顺序播报，不并发，避免叠音。支持训练中**暂停语音**和**停止语音**
- **计时精度：** 用时间戳差值计算，不依赖 Timer 绝对精度（防止 iOS 后台挂起）
- **跳过休息：** 用户可主动 skip 休息时间
- **间隔提醒：** 倒计时中每隔 N 秒播报剩余秒数（可配置 0/5/10/15/20/30 秒）
- **训练中语音提示：** 休息时间过半时播报下一动作名称，快到下一组时播报提示
- **提示音：** `lib/utils/beep.dart` 在训练关键节点播放短促提示音（macOS 生成 WAV 并通过 `afplay` 播放）

---

## 七、UI 关键设计

### 7.1 首页
- 计划卡片列表（名称、动作数、预计时长），使用 `PlanCard` widget
- 拖拽排序（`ReordableListView`）
- 点击计划卡片 → 确认弹窗 → 进入跟练
- 点击编辑图标 → 进入计划编辑页
- 空状态引导创建第一个计划

### 7.2 动作管理（Tab 页）
- 按肌群分组展示（`ExpansionTile`，默认展开）
- 搜索过滤
- 预置动作：灰色图标，点击不可编辑
- 自定义动作：蓝色图标，点击编辑，支持删除
- FAB 创建自定义动作（弹窗输入名称、肌群、类型）

### 7.3 计划编辑
- 计划名称/描述
- 动作列表（拖拽排序、点击编辑参数）
- 添加动作：弹出 `ExercisePicker` → 搜索/浏览 → 选择动作 → 设置参数（时长/组数/次数/休息）→ 确认添加

### 7.4 动作选择器（ExercisePicker）
- 按肌群分组（默认展开），搜索框 + 搜索历史（最近 5 条）
- 列表底部「自定义动作」入口，可直接在 picker 中创建新动作
- 选中动作后进入参数设置页（时长/组数/次数/休息），确认后返回数据

### 7.5 跟练页（核心）
- 环形倒计时（`CountdownRing` widget）+ 大字秒数
- 当前动作名 + 组号（如「第 2/3 组」）
- 整体进度条（N/M 动作完成）
- 暂停/跳过/恢复按钮
- 点击任意位置暂停（快捷暂停，可在设置中关闭）

### 7.6 训练总结
- 训练总时长
- 每个动作的完成状态
- 自动跳转（COMPLETED 后 3 秒）

### 7.7 历史记录
- 按日期倒序列表，显示计划名、日期、时长
- 点击进入 `HistoryDetailPage` 查看详情（每个动作的组数/次数/时长）
- 支持滑动删除

### 7.8 设置
- **教练分组：** 语音播报开关、震动反馈开关、间隔提醒（关闭/5/10/15/20/30 秒选择器）
- **界面分组：** 快捷暂停开关
- **关于分组：** 版本号 v1.1.1

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

实际 29 个 Dart 文件。

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

### ✅ v1.0+ 已实现

- 49 个预置动作库 + 自定义动作（创建/编辑/删除）
- 动作管理页面（Tab 页，按肌群分组，搜索）
- 训练计划 CRUD + 拖拽排序（首页 + 计划编辑页）
- 完整跟练教练（状态机 + TTS + 震动 + 暂停 + 跳过 + 快捷暂停）
- 间隔提醒（可配置秒数）+ 训练中语音提示
- 提示音（beep）
- 训练总结
- 历史记录 + 详情
- 设置页面（语音/震动/间隔提醒/快捷暂停）
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
