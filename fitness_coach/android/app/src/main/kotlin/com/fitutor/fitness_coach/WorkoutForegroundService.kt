package com.fitutor.fitness_coach

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.os.Build
import android.os.IBinder

class WorkoutForegroundService : Service() {
    private var silentTrack: AudioTrack? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = buildNotification()
        startForeground(NOTIFICATION_ID, notification)
        startSilentAudio()
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        stopSilentAudio()
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }

    // 持续播放静默音频，保持蓝牙 A2DP 链路活跃，避免 TTS 开头杂音
    private fun startSilentAudio() {
        try {
            val sampleRate = 44100
            val bufferSize = sampleRate / 10 // 0.1s
            val buffer = ShortArray(bufferSize) // 全零 = 静默
            silentTrack = AudioTrack.Builder()
                .setAudioAttributes(AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build())
                .setAudioFormat(AudioFormat.Builder()
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setSampleRate(sampleRate)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build())
                .setTransferMode(AudioTrack.MODE_STATIC)
                .setBufferSizeInBytes(bufferSize * 2)
                .build()
            silentTrack?.write(buffer, 0, bufferSize)
            silentTrack?.setLoopPoints(0, bufferSize, -1)
            silentTrack?.play()
        } catch (_: Exception) {}
    }

    private fun stopSilentAudio() {
        try {
            silentTrack?.pause()
            silentTrack?.flush()
            silentTrack?.stop()
            silentTrack?.release()
        } catch (_: Exception) {}
        silentTrack = null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "训练状态",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "训练进行中通知"
                setShowBadge(false)
                setSound(null, null)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder
            .setContentTitle("跟我练")
            .setContentText("训练进行中...")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .build()
    }

    companion object {
        private const val CHANNEL_ID = "workout_foreground"
        private const val NOTIFICATION_ID = 1001
    }
}
