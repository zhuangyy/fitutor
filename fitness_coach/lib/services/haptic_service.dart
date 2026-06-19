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
