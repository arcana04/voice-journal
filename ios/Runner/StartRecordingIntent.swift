import AppIntents
import UIKit

/// Siriから録音を開始する。iOSはSiriとの音声対話中（アプリがinactiveのまま）に
/// バックグラウンドから新規に録音を開始することを許可していないため、
/// openAppWhenRun = trueでアプリ自体をフォアグラウンドに開き、
/// ディープリンク（lib/services/deep_link_service.dart が処理）経由で
/// アプリ内の通常の録音開始（RecordTriggerStore）を叩く方式に統一している。
/// 録音の終了はアプリ内のボタンでのみ行う。
@available(iOS 16.0, *)
struct StartRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "録音を開始"
    static var description = IntentDescription("VoiceJournalを開いて録音を開始します。")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        if let url = URL(string: "voicejournal://record") {
            await UIApplication.shared.open(url)
        }
        return .result(dialog: "録音を開始します")
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
