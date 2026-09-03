import AVFoundation
import Foundation

@MainActor
final class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var lastError: String?
    /// 録音開始からの経過秒数。録音中のみ1秒ごとに更新される。
    @Published var elapsedSeconds: Int = 0

    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var startedAt: Date?
    private var timer: Timer?

    func requestPermissionIfNeeded(_ completion: @escaping (Bool) -> Void) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        @unknown default:
            completion(false)
        }
    }

    func start() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .default)
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

            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.record()
            self.recorder = recorder
            self.recordingURL = url
            self.isRecording = true
            self.lastError = nil
            self.startedAt = Date()
            self.elapsedSeconds = 0
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                // Timerのコールバック自体はMainActor分離されていないため、
                // @MainActor状態(startedAt/elapsedSeconds)へのアクセスは
                // 全てこのTask内で行う。
                Task { @MainActor in
                    guard let self, let startedAt = self.startedAt else { return }
                    self.elapsedSeconds = Int(Date().timeIntervalSince(startedAt))
                }
            }
        } catch {
            self.lastError = "\(error)"
        }
    }

    /// 録音を停止し、録音済みファイルのURLを返す（音声が無ければnil）。
    func stop() -> URL? {
        recorder?.stop()
        recorder = nil
        try? AVAudioSession.sharedInstance().setActive(false)
        isRecording = false
        timer?.invalidate()
        timer = nil
        startedAt = nil
        return recordingURL
    }
}
