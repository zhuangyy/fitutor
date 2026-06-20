import 'dart:io';
import 'package:flutter/services.dart';

/// 平台后台保活管理器。
/// iOS: 静默音频保持 AVAudioSession 活跃。
/// Android: 前台 Service 保持进程存活。
class BackgroundServiceManager {
  static const _iosChannel = MethodChannel('com.fitutor/audio_bridge');
  static const _androidChannel = MethodChannel('com.fitutor/foreground_service');

  /// 开始训练时调用，启动平台后台保活。
  Future<void> startWorkout() async {
    if (Platform.isIOS) {
      try {
        await _iosChannel.invokeMethod('startSilentAudio');
      } catch (_) {
        // 静默音频失败不阻塞训练流程
      }
    } else if (Platform.isAndroid) {
      try {
        await _androidChannel.invokeMethod('startService');
      } catch (_) {
        // 前台 Service 失败不阻塞训练流程
      }
    }
  }

  /// 停止训练时调用，停止平台后台保活。
  Future<void> stopWorkout() async {
    if (Platform.isIOS) {
      try {
        await _iosChannel.invokeMethod('stopSilentAudio');
      } catch (_) {}
    } else if (Platform.isAndroid) {
      try {
        await _androidChannel.invokeMethod('stopService');
      } catch (_) {}
    }
  }

  /// 播放短促提示音（Android 使用 ToneGenerator）。
  Future<void> playBeep() async {
    if (Platform.isAndroid) {
      try {
        await _androidChannel.invokeMethod('playBeep');
      } catch (_) {}
    }
  }
}
