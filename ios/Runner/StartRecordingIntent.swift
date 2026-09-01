import AppIntents
import UIKit

/// Siri/ショートカットからアプリを開かずに録音を開始する。ペアリング未完了・
/// マイク権限未許可の場合は、通常の`voicejournal://record`を開くフォールバックで
/// アプリ側のUIに任せる（初回セットアップやエラー確認はアプリ内で行うのが自然なため）。
@available(iOS 16.0, *)
struct StartRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "録音を開始"
    static var description = IntentDescription("VoiceJournalで新しい音声の記録をバックグラウンドで開始します。")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard SiriKeychainStore.isPaired else {
            openAppToRecord()
            return .result(dialog: "アプリを開いて録音を開始します")
        }

        let granted = await BackgroundAudioRecorder.shared.requestPermissionIfGranted()
        guard granted else {
            openAppToRecord()
            return .result(dialog: "マイクの許可が必要です。アプリを開きます")
        }

        do {
            try await BackgroundAudioRecorder.shared.start()
        } catch {
            openAppToRecord()
            return .result(dialog: "録音を開始できなかったため、アプリを開きます")
        }

        return .result(dialog: "録音を開始しました")
    }

    private func openAppToRecord() {
        if let url = URL(string: "voicejournal://record") {
            UIApplication.shared.open(url)
        }
    }
}

/// 「録音を終了」で呼び出し、バックグラウンド録音を停止してアップロード・
/// 文字起こし・構造化までを行う。実行中に画面は開かず、結果はSiriの音声で伝える。
@available(iOS 16.0, *)
struct StopRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "録音を終了"
    static var description = IntentDescription("バックグラウンドで録音した内容をVoiceJournalに保存します。")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let audioURL: URL
        do {
            audioURL = try await BackgroundAudioRecorder.shared.stop()
        } catch {
            return .result(dialog: "録音中の記録が見つかりませんでした")
        }

        let taskId = UIApplication.shared.beginBackgroundTask(withName: "SiriVoiceMemoUpload")
        defer {
            if taskId != .invalid {
                UIApplication.shared.endBackgroundTask(taskId)
            }
        }

        do {
            let result = try await SiriVoiceMemoUploader.upload(audioFileURL: audioURL)
            try? FileManager.default.removeItem(at: audioURL)
            return .result(dialog: "保存しました。\(result.summary)")
        } catch {
            return .result(dialog: "保存に失敗しました。アプリを開いて確認してください")
        }
    }
}

@available(iOS 16.0, *)
struct VoiceJournalShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartRecordingIntent(),
            phrases: [
                "\(.applicationName)で録音を開始",
                "\(.applicationName)で記録して",
                "Start recording with \(.applicationName)",
            ],
            shortTitle: "録音を開始",
            systemImageName: "mic.fill"
        )
        AppShortcut(
            intent: StopRecordingIntent(),
            phrases: [
                "\(.applicationName)で録音を終了",
                "\(.applicationName)の録音を止めて",
                "Stop recording with \(.applicationName)",
            ],
            shortTitle: "録音を終了",
            systemImageName: "stop.circle.fill"
        )
    }
}
