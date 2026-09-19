import AVFoundation
import Foundation

@MainActor
final class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var lastError: String?
    /// 録音開始からの経過秒数。録音中のみ1秒ごとに更新される。
    @Published var elapsedSeconds: Int = 0
    /// 電話・Siri等のシステム割り込みで録音が中断された際、そこまでに録れた分の
    /// ファイルURL。ContentView側でこれを観測し、保存(アップロード)を促す。
    @Published var interruptedRecordingURL: URL?

    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var startedAt: Date?
    private var timer: Timer?

    private static let inProgressPathKey = "com.arcana04.voicejournal.watch.inProgressRecordingPath"

    override init() {
        super.init()
        // 電話・Siri等のシステム割り込みで録音が実際には止まっているのに、
        // 画面上は「録音中」のまま何も録れていない、という状態を避けるため監視する。
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

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
        var didActivateSession = false
        do {
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)
            didActivateSession = true

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
            // 強制終了時にこの録音を後から見つけられるよう、開始時点でパスを
            // 永続化しておく。アップロード+保存が完了するまでは消さない
            // (呼び出し側がEntryStore.save成功後にclearRecoverableRecordingを呼ぶ)。
            Self.markInProgress(url)
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
            // setActive(true)だけ成功してAVAudioRecorderの生成に失敗した場合、
            // セッションをアクティブなままにしておくとマイクを掴んだ状態が残ってしまう。
            if didActivateSession {
                try? session.setActive(false)
            }
            self.lastError = "\(error)"
        }
    }

    /// 録音を停止し、録音済みファイルのURLを返す（音声が無ければnil）。
    @discardableResult
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

    @objc private func handleInterruption(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            guard isRecording else { return }
            // 電話・Siri等の割り込みで録音が実際には止まっている可能性が高い。
            // 「録音中」表示のまま黙って何も録れていない状態を避けるため、
            // ここまでに録れた分を確定して停止する。AVAudioRecorderは一度
            // stop()すると同じインスタンスでは再開できないため、続きは
            // ユーザーが録音ボタンを再度押した新規録音として扱う(自動再開はしない)。
            if let url = stop() {
                interruptedRecordingURL = url
            }
        case .ended:
            // 上のとおり.beganの時点で既に停止・確定させているため、ここで
            // 自動再開すべき録音は無い(.shouldResumeでも何もしない)。
            break
        @unknown default:
            break
        }
    }

    // MARK: - 強制終了からの復元

    private static func markInProgress(_ url: URL) {
        UserDefaults.standard.set(url.path, forKey: inProgressPathKey)
    }

    /// 前回、録音開始はしたもののEntryStore.saveまで完了しなかった
    /// (Watchアプリの強制終了・クラッシュ等)録音ファイルが残っていれば、
    /// そのURLを返す。ファイルが既に存在しなければマーカーも消しておく。
    static var recoverableRecordingURL: URL? {
        guard let path = UserDefaults.standard.string(forKey: inProgressPathKey) else { return nil }
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: url.path) else {
            UserDefaults.standard.removeObject(forKey: inProgressPathKey)
            return nil
        }
        return url
    }

    /// 録音が安全に保存された(EntryStore.save成功)、またはユーザーが破棄を
    /// 選んだ際に呼ぶ。`matching`を渡した場合、現在のマーカーがそのURLと
    /// 一致する時だけクリアする(その間に別の録音が新たに開始されていた場合に
    /// 誤って別ファイルのマーカーを消さないための防御)。
    static func clearRecoverableRecording(matching url: URL? = nil, deleteFile: Bool = false) {
        if let url {
            guard UserDefaults.standard.string(forKey: inProgressPathKey) == url.path else { return }
        }
        if deleteFile, let path = UserDefaults.standard.string(forKey: inProgressPathKey) {
            try? FileManager.default.removeItem(atPath: path)
        }
        UserDefaults.standard.removeObject(forKey: inProgressPathKey)
    }
}
