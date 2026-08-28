import WidgetKit
import SwiftUI

/// タップすると `voicejournal://record` を開き、メインアプリ側で自動的に録音を
/// 開始する（アプリを開いた直後に自動開始するだけで、ウィジェット自体は録音しない）。
struct RecordEntry: TimelineEntry {
    let date: Date
}

struct RecordProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecordEntry {
        RecordEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (RecordEntry) -> Void) {
        completion(RecordEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecordEntry>) -> Void) {
        completion(Timeline(entries: [RecordEntry(date: Date())], policy: .never))
    }
}

struct RecordWidgetEntryView: View {
    var entry: RecordProvider.Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "mic.fill")
                    .font(.title2)
            }
        case .accessoryInline:
            Label("録音を開始", systemImage: "mic.fill")
        case .systemSmall:
            VStack(spacing: 10) {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 40))
                Text("録音を開始")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .widgetBackground()
        default:
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .font(.title3)
                Text("録音を開始")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .widgetBackground()
        }
    }
}

private extension View {
    /// ホーム画面ウィジェット（systemSmall等）はiOS 17以降 `containerBackground` が必須。
    /// ロック画面用ファミリー（accessory系）には適用されない分岐なので、この拡張は
    /// systemSmall/systemMedium等でのみ呼ばれる想定。
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(.fill.tertiary, for: .widget)
        } else {
            self.padding().background(Color(.systemBackground))
        }
    }
}

struct RecordWidget: Widget {
    let kind: String = "RecordWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecordProvider()) { entry in
            RecordWidgetEntryView(entry: entry)
                .widgetURL(URL(string: "voicejournal://record"))
        }
        .configurationDisplayName("VoiceJournal")
        .description("タップで録音をすぐに開始します。")
        .supportedFamilies([
            .accessoryCircular, .accessoryRectangular, .accessoryInline,
            .systemSmall,
        ])
    }
}
