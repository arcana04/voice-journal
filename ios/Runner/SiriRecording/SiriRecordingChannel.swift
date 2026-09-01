import Flutter

/// lib/services/siri_recording_setup_service.dart から、mintWatchPairingToken
/// で取得したcustomToken/deviceId/deviceSecretを受け取り、SiriAuthClientの
/// ペアリングを完了させるMethodChannel。
class SiriRecordingChannel: NSObject {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "voicejournal/siri_recording",
            binaryMessenger: registrar.messenger()
        )
        let instance = SiriRecordingChannel()
        channel.setMethodCallHandler { call, result in
            instance.handle(call, result: result)
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isPaired":
            result(SiriKeychainStore.isPaired)
        case "completePairing":
            completePairing(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func completePairing(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard
            let args = call.arguments as? [String: Any],
            let customToken = args["customToken"] as? String,
            let deviceId = args["deviceId"] as? String,
            let deviceSecret = args["deviceSecret"] as? String
        else {
            result(FlutterError(code: "invalid_args", message: "customToken/deviceId/deviceSecretが必要です", details: nil))
            return
        }

        Task {
            do {
                try await SiriAuthClient.shared.completePairing(
                    customToken: customToken, deviceId: deviceId, deviceSecret: deviceSecret
                )
                result(true)
            } catch {
                result(FlutterError(code: "pairing_failed", message: "\(error)", details: nil))
            }
        }
    }
}
