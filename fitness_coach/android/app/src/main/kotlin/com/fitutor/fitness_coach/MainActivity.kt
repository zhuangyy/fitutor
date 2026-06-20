package com.fitutor.fitness_coach

import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.fitutor/foreground_service"
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        val intent = Intent(this, WorkoutForegroundService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            @Suppress("DEPRECATION")
                            startService(intent)
                        }
                        result.success(true)
                    }
                    "stopService" -> {
                        val intent = Intent(this, WorkoutForegroundService::class.java)
                        stopService(intent)
                        result.success(true)
                    }
                    "playBeep" -> {
                        playBeep()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun playBeep() {
        mainHandler.post {
            try {
                val sampleRate = 44100
                val durationMs = 250
                val frequency = 880.0
                val numSamples = (sampleRate * durationMs / 1000)
                val buffer = ShortArray(numSamples)
                for (i in 0 until numSamples) {
                    val envelope = if (i < numSamples / 10) i.toDouble() / (numSamples / 10) else 1.0
                    buffer[i] = (Math.sin(2.0 * Math.PI * frequency * i / sampleRate) * 32767 * 0.9 * envelope).toInt().toShort()
                }
                val track = AudioTrack.Builder()
                    .setAudioAttributes(AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build())
                    .setAudioFormat(AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(sampleRate)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build())
                    .setTransferMode(AudioTrack.MODE_STATIC)
                    .setBufferSizeInBytes(numSamples * 2)
                    .build()
                track.write(buffer, 0, numSamples)
                track.play()
                mainHandler.postDelayed({
                    try { track.stop(); track.release() } catch (_: Exception) {}
                }, durationMs + 100L)
            } catch (_: Exception) {}
        }
    }
}
