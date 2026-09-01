import AVFoundation
import Foundation

/// Siri/ショートカットから呼ばれるStartRecordingIntent/StopRecordingIntentの間、
/// アプリを前面化せずに録音状態を保持するためのシングルトン。RunnerはInfo.plistで
/// UIBackgroundModes=audioを宣言済みなので、録音セッションがアクティブな間はOSに
/// プロセスを一時停止されない（Apple Watch側のAudioRecorder.swiftと録音設定は揃えている）。
actor BackgroundAudioRecorder {
    static let shared = BackgroundAudioRecorder()

    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?

    enum RecorderError: Error {
        case permissionDenied
        case alreadyRecording
        case notRecording
        case failedToStart(Error)
    }

    var isRecording: Bool { recorder != nil }

    func requestPermissionIfGranted() async -> Bool {
        await withCheckedContinuation { continuation in
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                continuation.resume(returning: true)
            case .denied:
                continuation.resume(returning: false)
            case .undetermined:
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            @unknown default:
                continuation.resume(returning: false)
            }
        }
    }

    func start() throws {
        guard recorder == nil else { throw RecorderError.alreadyRecording }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("m4a")

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
            ]

            let newRecorder = try AVAudioRecorder(url: url, settings: settings)
            guard newRecorder.record() else {
                throw RecorderError.failedToStart(SiriAuthError.invalidResponse)
            }
            recorder = newRecorder
            recordingURL = url
        } catch {
            throw RecorderError.failedToStart(error)
        }
    }

    /// 録音を停止し、録音済みファイルのURLを返す。
    func stop() throws -> URL {
        guard let recorder, let recordingURL else { throw RecorderError.notRecording }
        recorder.stop()
        self.recorder = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return recordingURL
    }
}
