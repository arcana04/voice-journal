import SwiftUI

/// 録音〜保存の画面状態。録音停止と同時にAIの既定分類でFirestoreへ保存して
/// しまう(データを失わないことを優先)。resultの画面はその後の「確認・分類の
/// 訂正だけ」を担い、タスク/日記/アイデアのボタンを押すと単一項目にまとめ
/// 直して上書き保存する。
private enum FlowState {
    case idle
    case uploading
    case result(ProcessVoiceMemoResult, createdAt: Date, entryId: String, category: EntryCategory)
    case error(String)
}

struct ContentView: View {
    @StateObject private var pairing = PairingReceiver.shared
    @StateObject private var recorder = AudioRecorder()
    @State private var flow: FlowState = .idle
    @State private var isSavingCategory = false

    var body: some View {
        VStack(spacing: 10) {
            if !pairing.isPaired {
                Text("iPhoneアプリでペアリングしてください")
                    .multilineTextAlignment(.center)
                    .font(.footnote)
                if let lastError = pairing.lastError {
                    Text(lastError)
                        .multilineTextAlignment(.center)
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            } else {
                content
            }
        }
        .padding()
        .onAppear {
            recorder.requestPermissionIfNeeded { _ in }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch flow {
        case .idle:
            recordButton
            if recorder.isRecording {
                Text(elapsedLabel)
                    .font(.title3)
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }
        case .uploading:
            ProgressView()
            Text("アップロード中…")
                .font(.caption2)
                .foregroundColor(.secondary)
        case .result(let result, let createdAt, let entryId, let category):
            resultView(result: result, createdAt: createdAt, entryId: entryId, category: category)
        case .error(let message):
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.caption2)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
            Button("閉じる") { flow = .idle }
                .buttonStyle(.bordered)
        }
    }

    private var elapsedLabel: String {
        let seconds = recorder.elapsedSeconds
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private var recordButton: some View {
        Button(action: toggleRecording) {
            Image(systemName: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(recorder.isRecording ? .red : .accentColor)
        }
        .buttonStyle(.plain)
    }

    private func resultView(
        result: ProcessVoiceMemoResult,
        createdAt: Date,
        entryId: String,
        category: EntryCategory
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(result.summary)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            HStack(spacing: 4) {
                ForEach(EntryCategory.allCases, id: \.self) { option in
                    Button(option.label) {
                        selectCategory(option, result: result, createdAt: createdAt, entryId: entryId)
                    }
                    .buttonStyle(.bordered)
                    .tint(option == category ? .accentColor : .gray)
                    .disabled(isSavingCategory)
                    .font(.caption2)
                }
            }
            Button("完了") { flow = .idle }
                .buttonStyle(.borderedProminent)
                .padding(.top, 2)
        }
    }

    private func selectCategory(
        _ newCategory: EntryCategory,
        result: ProcessVoiceMemoResult,
        createdAt: Date,
        entryId: String
    ) {
        guard case .result(_, _, _, let current) = flow, current != newCategory else { return }
        isSavingCategory = true
        flow = .result(result, createdAt: createdAt, entryId: entryId, category: newCategory)
        Task {
            do {
                try await EntryStore.recategorize(
                    result: result,
                    createdAt: createdAt,
                    entryId: entryId,
                    category: newCategory
                )
            } catch {
                // 最初の保存自体は既に成功しているので、分類の訂正だけ失敗しても
                // データは残る。ここでは静かに諦める(次に開いたときiPhone側で直せる)。
            }
            await MainActor.run { isSavingCategory = false }
        }
    }

    private func toggleRecording() {
        if recorder.isRecording {
            guard let url = recorder.stop() else { return }
            flow = .uploading
            Task {
                do {
                    let result = try await VoiceMemoUploader.upload(audioFileURL: url)
                    let createdAt = Date()
                    let entryId = EntryStore.generateEntryId()
                    let category = EntryCategory.primary(for: result)
                    try await EntryStore.save(result: result, createdAt: createdAt, entryId: entryId)
                    await MainActor.run {
                        flow = .result(result, createdAt: createdAt, entryId: entryId, category: category)
                    }
                } catch {
                    await MainActor.run {
                        flow = .error("\(error)")
                    }
                }
            }
        } else {
            flow = .idle
            recorder.start()
        }
    }
}
