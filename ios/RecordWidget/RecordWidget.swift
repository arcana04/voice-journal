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
        default:
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .font(.title3)
                Text("録音を開始")
                    .font(.headline)
            }
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
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
