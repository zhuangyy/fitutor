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
      await _flutterTts.awaitSpeakCompletion(true);
      _initialized = true;
      _available = true;
    } catch (e) {
      _available = false;
    }
  }

  /// 播放欢迎词并预热引擎，应在首帧渲染后调用。fire-and-forget，不阻塞 UI。
  void warmUp() {
    if (!_initialized || !_available) return;
    _flutterTts.speak('来，一起锻炼吧').catchError((_) {});
  }

  Future<void> speak(String text) async {
    if (_isMuted || !_available) return;
    try {
      // 短暂延迟让音频管线稳定，避免开头杂音
      await Future.delayed(const Duration(milliseconds: 80));
      await _flutterTts.speak(text);
    } catch (_) {
      _available = false;
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      // 停止后等待音频管线释放，避免下次 speak 开头杂音
      await Future.delayed(const Duration(milliseconds: 50));
    } catch (_) {}
  }

  void mute() => _isMuted = true;
  void unmute() => _isMuted = false;
  void toggleMute() => _isMuted = !_isMuted;

  void dispose() {
    _flutterTts.stop();
  }
}
