import 'package:flutter/material.dart';
import 'package:fitness_coach/services/tts_service.dart';
import 'package:fitness_coach/services/haptic_service.dart';
import 'package:fitness_coach/services/notification_service.dart';

class SettingsProvider extends ChangeNotifier {
  final TtsService _tts;
  final HapticService _haptic;
  final NotificationService _notification;
  int _reminderInterval = 10; // 默认10秒
  bool _tapToPause = false;

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
  int get reminderInterval => _reminderInterval;
  bool get tapToPause => _tapToPause;
  String get reminderIntervalLabel =>
      _reminderInterval == 0 ? '关闭' : '${_reminderInterval}秒';

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

  void setReminderInterval(int seconds) {
    _reminderInterval = seconds;
    notifyListeners();
  }

  void toggleTapToPause() {
    _tapToPause = !_tapToPause;
    notifyListeners();
  }
}
