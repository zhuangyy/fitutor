import Flutter
import UIKit
import AVFoundation

/// 静默音频播放器：循环播放空 buffer，保持后台音频会话活跃。
class SilentAudioPlayer {
    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?

    func start() {
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)

        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4410)!
        buffer.frameLength = 4410
        player.scheduleBuffer(buffer, at: nil, options: .loops)

        do {
            try engine.start()
            player.play()
            self.engine = engine
            self.playerNode = player
        } catch {
            NSLog("SilentAudioPlayer start failed: \(error)")
        }
    }

    func stop() {
        playerNode?.stop()
        engine?.stop()
        playerNode = nil
        engine = nil
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    private let silentPlayer = SilentAudioPlayer()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            NSLog("AVAudioSession config failed: \(error)")
        }
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

        let channel = FlutterMethodChannel(
            name: "com.fitutor/audio_bridge",
            binaryMessenger: engineBridge.engine.binaryMessenger)
        channel.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "startSilentAudio":
                do {
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch {
                    NSLog("AVAudioSession setActive failed: \(error)")
                }
                self?.silentPlayer.start()
                result(nil)
            case "stopSilentAudio":
                self?.silentPlayer.stop()
                do {
                    try AVAudioSession.sharedInstance().setActive(false)
                } catch {
                    NSLog("AVAudioSession setActive failed: \(error)")
                }
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
