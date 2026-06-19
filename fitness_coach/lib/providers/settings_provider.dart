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
