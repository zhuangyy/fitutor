import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// 播放短促提示音。macOS 上生成并播放 beep 音效，其他平台跳过。
Future<void> playBeep() async {
  if (!Platform.isMacOS) return;
  try {
    final beepFile = File('${Directory.systemTemp.path}/fitutor_beep.wav');
    if (!await beepFile.exists()) {
      await beepFile.writeAsBytes(_generateBeep());
    }
    await Process.run('afplay', [beepFile.path]);
  } catch (_) {
    // 静默失败
  }
}

Uint8List _generateBeep() {
  const sampleRate = 22050;
  const duration = 0.25;
  const frequency = 440;
  final numSamples = (sampleRate * duration).toInt();
  final samples = Int16List(numSamples);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final fadeInEnd = (sampleRate * 0.01).toInt();
    final fadeOutStart = numSamples - (sampleRate * 0.03).toInt();
    final envelope = (i < fadeInEnd ? i / fadeInEnd : 1.0) *
        (i > fadeOutStart ? (numSamples - i) / (numSamples - fadeOutStart) : 1.0);
    samples[i] =
        (sin(2 * pi * frequency * t) * 32767 * 0.7 * envelope).toInt();
  }

  final builder = BytesBuilder();
  final dataSize = numSamples * 2;

  // RIFF header
  builder.add('RIFF'.codeUnits);
  builder.add(_u32le(36 + dataSize));
  builder.add('WAVE'.codeUnits);

  // fmt chunk
  builder.add('fmt '.codeUnits);
  builder.add(_u32le(16)); // PCM
  builder.add(_u16le(1)); // mono
  builder.add(_u16le(1));
  builder.add(_u32le(sampleRate));
  builder.add(_u32le(sampleRate * 2)); // byte rate
  builder.add(_u16le(2)); // block align
  builder.add(_u16le(16)); // bits per sample

  // data chunk
  builder.add('data'.codeUnits);
  builder.add(_u32le(dataSize));
  builder.add(samples.buffer.asUint8List());

  return builder.toBytes();
}

Uint8List _u32le(int v) =>
    Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.little);

Uint8List _u16le(int v) =>
    Uint8List(2)..buffer.asByteData().setUint16(0, v, Endian.little);
