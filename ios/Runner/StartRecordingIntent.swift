import AppIntents
import UIKit

/// Siri/ショートカットから呼び出すと `voicejournal://record` を開き、
/// RecordWidget と同じ経路でメインアプリ側の録音を自動開始する。
@available(iOS 16.0, *)
struct StartRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "録音を開始"
    static var description = IntentDescription("VoiceJournalで新しい音声の記録を開始します。")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        if let url = URL(string: "voicejournal://record") {
            await UIApplication.shared.open(url)
        }
        return .result()
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
    }
}
