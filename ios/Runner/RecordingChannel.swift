import Flutter

/// アプリ内の通常の録音UI（lib/services/recorder_service.dart）から、
/// BackgroundAudioRecorder（ios/Runner/SiriRecording/参照）を操作するための
/// MethodChannel。UIBackgroundModes=audio対応のネイティブ録音エンジンを使うことで、
/// 録音中に画面をロックしてもiOSにプロセスを一時停止されずに録音を継続できる。
class RecordingChannel: NSObject {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "voicejournal/recording",
            binaryMessenger: registrar.messenger()
        )
        let instance = RecordingChannel()
        channel.setMethodCallHandler { call, result in
            instance.handle(call, result: result)
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "hasPermission":
            Task {
                let granted = await BackgroundAudioRecorder.shared.requestPermissionIfGranted()
                result(granted)
            }
        case "start":
            Task {
                do {
                    try await BackgroundAudioRecorder.shared.start()
                    result(nil)
                } catch {
                    result(FlutterError(code: "start_failed", message: "\(error)", details: nil))
                }
            }
        case "stop":
            Task {
                do {
                    let url = try await BackgroundAudioRecorder.shared.stop()
                    result(url.path)
                } catch {
                    result(FlutterError(code: "stop_failed", message: "\(error)", details: nil))
                }
            }
        case "cancel":
            Task {
                await BackgroundAudioRecorder.shared.cancel()
                result(nil)
            }
        case "getAmplitude":
            Task {
                let value = await BackgroundAudioRecorder.shared.currentAmplitude()
                result(value.map { Double($0) })
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
