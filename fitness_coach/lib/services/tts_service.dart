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
      _initialized = true;
      _available = true;
    } catch (e) {
      _available = false;
    }
  }

  Future<void> speak(String text) async {
    if (_isMuted || !_available) return;
    try {
      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.speak(text);
    } catch (_) {
      _available = false;
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }

  void mute() => _isMuted = true;
  void unmute() => _isMuted = false;
  void toggleMute() => _isMuted = !_isMuted;

  void dispose() {
    _flutterTts.stop();
  }
}
