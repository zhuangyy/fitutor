import 'dart:io';
import 'package:fitness_coach/services/background_service_manager.dart';

final _bgService = BackgroundServiceManager();

/// 播放短促提示音。
/// Android: ToneGenerator 响亮的短促 beep。
/// iOS: 系统点击音。
Future<void> playBeep() async {
  if (Platform.isAndroid || Platform.isIOS) {
    await _bgService.playBeep();
  }
}
