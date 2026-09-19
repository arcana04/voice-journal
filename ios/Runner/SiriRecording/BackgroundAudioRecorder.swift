import AVFoundation
import Foundation

/// アプリ内の通常録音（RecordingChannel経由）が使う、録音状態を保持する
/// シングルトン。RunnerはInfo.plistでUIBackgroundModes=audioを宣言済みなので、
/// 録音セッションがアクティブな間はアプリをバックグラウンドに回しても（画面ロック等）
/// OSにプロセスを一時停止されない（Apple Watch側のAudioRecorder.swiftと録音設定は揃えている）。
actor BackgroundAudioRecorder {
    static let shared = BackgroundAudioRecorder()

    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?
    /// 電話・Siri等の割り込みでOSに一時停止されている間true。[isRecording]は
    /// これを踏まえて「実際にキャプチャできているか」を返す（recorderを保持
    /// しているだけの状態と区別する）。
    private var isInterrupted = false
    private var observersRegistered = false

    enum RecorderError: Error {
        case permissionDenied
        case alreadyRecording
        case notRecording
        case failedToStart(Error)
        case recordFailedToStart
    }

    /// 実際に音声をキャプチャ中かどうか。単に`recorder`オブジェクトを保持して
    /// いるかではなく、割り込み([isInterrupted])で一時停止されていないかも
    /// 見る——そうしないと、電話・Siri等の割り込み中もFlutter側の
    /// `isRecording()`がtrueを返し続け、UIが「録音継続中」を表示したまま
    /// 実際には無音区間が生まれてしまう。
    var isRecording: Bool { recorder != nil && !isInterrupted }

    /// 今まさに書き込み中の録音ファイルのパス（無ければnil）。強制終了リカバリの
    /// オーファン録音スキャンが、開始直後のこのファイルを誤って削除しないよう、
    /// Flutter側が除外パスとして使う。
    var currentRecordingPath: String? { recordingURL?.path }

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

        registerInterruptionObserversIfNeeded()
        isInterrupted = false

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)

            // ファイル名にAndroid側(recorder_service.dart)と同じ"voicejournal_"
            // プレフィックスを付ける。Dart側のfindOrphanedRecordings()はこの
            // プレフィックスで保存先ディレクトリ内の未処理録音を検知するが、以前は
            // UUIDのみのファイル名だったため一度もマッチせず、iOSで録音中に
            // アプリが強制終了された場合の復旧ダイアログが機能していなかった
            // （録音が復旧手段なく失われていた）。
            //
            // 保存先はApplication Support配下（[Self.recordingsDirectory]）——
            // NSTemporaryDirectoryはアプリ未起動中にOSがいつでも中身を消してよい
            // 領域と定義されており、強制終了からのリカバリ（次回起動までファイルが
            // 残っている前提）と矛盾するため使わない。Dart側のrecorder_service.dart
            // も同じ`recordings`ディレクトリ名で揃えている。
            let recordingsDir = try Self.recordingsDirectory()
            let url = recordingsDir
                .appendingPathComponent("voicejournal_\(UUID().uuidString)")
                .appendingPathExtension("m4a")

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
            ]

            let newRecorder = try AVAudioRecorder(url: url, settings: settings)
            newRecorder.isMeteringEnabled = true
            guard newRecorder.record() else {
                throw RecorderError.recordFailedToStart
            }
            recorder = newRecorder
            recordingURL = url
        } catch {
            throw RecorderError.failedToStart(error)
        }
    }

    /// 録音を停止し、録音済みファイルのURLを返す。割り込みで一時停止されたまま
    /// 再開できなかった場合でも、それまでにキャプチャできた分を確定して返す。
    func stop() throws -> URL {
        guard let recorder, let recordingURL else { throw RecorderError.notRecording }
        recorder.stop()
        self.recorder = nil
        isInterrupted = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return recordingURL
    }

    /// 録音を破棄する（ファイルは保存しない）。
    func cancel() {
        recorder?.stop()
        if let recordingURL {
            try? FileManager.default.removeItem(at: recordingURL)
        }
        recorder = nil
        recordingURL = nil
        isInterrupted = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// 直近の平均音量（dBFS、無音に近いほど-160に近づく）。録音中でなければnil。
    func currentAmplitude() -> Float? {
        guard let recorder else { return nil }
        recorder.updateMeters()
        return recorder.averagePower(forChannel: 0)
    }

    // MARK: - 割り込み（電話・Siri等）対応

    /// シングルトンなのでアプリ生存中はずっと購読したままでよく、明示的な解除は不要。
    private func registerInterruptionObserversIfNeeded() {
        guard !observersRegistered else { return }
        observersRegistered = true
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: nil
        ) { [weak self] notification in
            guard let self else { return }
            Task { await self.handleInterruption(notification) }
        }
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: nil
        ) { [weak self] notification in
            guard let self else { return }
            Task { await self.handleRouteChange(notification) }
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard recorder != nil,
            let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            // OSがセッションを一時停止した（電話着信・Siri等）。pause()はファイルを
            // 開いたままにするため、再開できれば続きから録音できる。[isInterrupted]
            // により、この間[isRecording]はfalseを返すようになる——Flutter側が
            // 「録音中」表示を続けたまま実際には無音になる、という食い違いを防ぐ。
            recorder?.pause()
            isInterrupted = true
        case .ended:
            let optionsValue = info[AVAudioSessionInterruptionOptionsKey] as? UInt
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue ?? 0)
            if options.contains(.shouldResume) {
                let session = AVAudioSession.sharedInstance()
                do {
                    try session.setActive(true)
                    if recorder?.record() == true {
                        isInterrupted = false
                        return
                    }
                } catch {
                    // 再開に失敗。isInterrupted=trueのまま下に抜け、呼び出し側
                    // （Flutter）が「録音が途中で止まった」と検知できるようにする。
                }
            }
            // shouldResumeが無い、または再開自体に失敗した場合はisInterrupted=true
            // のままにしておく。Flutter側は定期的に`isRecording()`をポーリングして
            // おり、これがfalseに変わったことを検知すると、それまでキャプチャできた
            // 分を確定させて処理に回す（home_screen.dartの_startTrackingTimers参照）。
        @unknown default:
            break
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        // 入力デバイスの切断（Bluetoothヘッドセットが外れた等）はAVAudioRecorderが
        // 通常そのまま内蔵マイクへフォールバックして録音を継続するため、ここでは
        // 状態を壊さないよう何もしない（将来的に無音化するケースがあっても、
        // 振幅監視による無音自動停止が最終的な安全網としてカバーする）。
        _ = notification
    }

    // MARK: - 保存先ディレクトリ

    /// 録音ファイルの保存先。詳細は[start]内のコメントを参照。
    private static func recordingsDirectory() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        var dir = base.appendingPathComponent("recordings", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            // 音声はユーザーが明示的にiCloud/iTunesバックアップへ含めたい類の
            // データではなく（処理完了後は端末からもすぐ削除される一時的な
            // キャッシュ相当）、バックアップ容量を無駄に圧迫しないよう除外する。
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? dir.setResourceValues(values)
        }
        return dir
    }
}
