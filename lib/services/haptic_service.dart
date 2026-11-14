import 'package:flutter/services.dart';

class HapticService {
  bool enabled = true;

  void light() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
  }

  void medium() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
  }

  void heavy() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// 倒计时最后5秒每秒震动：5,4→light, 3→medium, 2→medium, 1→heavy
  void countdownBuzz(int remainingSeconds) {
    if (!enabled) return;
    switch (remainingSeconds) {
      case 5:
      case 4:
        light();
        break;
      case 3:
      case 2:
        medium();
        break;
      case 1:
        heavy();
        break;
    }
  }
}
