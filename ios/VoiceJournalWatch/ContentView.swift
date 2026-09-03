import SwiftUI

/// 録音〜保存の画面状態。録音停止と同時にAIの既定分類でFirestoreへ保存して
/// しまう(データを失わないことを優先)。resultの画面はその後の「確認・分類の
/// 訂正だけ」を担う。1回の発話がタスク/日記/アイデアのどれか1件だけに
/// 仕分けられた場合のみ、ボタンで選び直せる(単一項目にまとめ直して上書き)。
/// 複数項目(タスク+日記など)に仕分けられた場合は、1つのボタンで上書きすると
/// 他の項目を消してしまうため、内訳を表示するだけにして訂正はiPhone側の
/// 3カラムレビュー画面に委ねる。
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
        ScrollView {
            VStack(spacing: 8) {
                if result.totalItemCount <= 1 {
                    HStack(spacing: 4) {
                        Image(systemName: category.iconName)
                        Text("\(category.label)として保存しました")
                    }
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
                    .multilineTextAlignment(.center)
                } else {
                    // 1回の発話から複数項目(タスク+日記など)に仕分けられた場合、
                    // 単一のカテゴリボタンで上書きすると他の項目を消してしまう。
                    // ここでは内訳を表示するだけにとどめ、訂正はiPhone側に委ねる。
                    Text("\(result.breakdownSummary)に仕分けて保存しました")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                        .multilineTextAlignment(.center)
                }

                // 省略せず全文表示。ScrollViewで縦にスクロールして読める。
                Text(result.summary)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if result.totalItemCount <= 1 {
                    Text("分類が違う場合はタップして変更")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        ForEach(EntryCategory.allCases, id: \.self) { option in
                            categoryButton(
                                option,
                                isSelected: option == category,
                                result: result,
                                createdAt: createdAt,
                                entryId: entryId
                            )
                        }
                    }
                } else {
                    Text("複数項目に分かれているため、訂正はiPhone側のアプリで行ってください")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button("完了") { flow = .idle }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 2)
        }
    }

    @ViewBuilder
    private func categoryButton(
        _ option: EntryCategory,
        isSelected: Bool,
        result: ProcessVoiceMemoResult,
        createdAt: Date,
        entryId: String
    ) -> some View {
        let action = { selectCategory(option, result: result, createdAt: createdAt, entryId: entryId) }
        // 3つ横並びだとWatch画面幅の余裕が無いため、ボタンの中身はテキストのみ
        // にする(アイコン+テキストだと幅が足りず折り返す機種がある)。選択中/
        // 非選択の区別はborderedProminent(塗り)/bordered(枠のみ)で付ける。
        if isSelected {
            Button(option.label, action: action)
                .buttonStyle(.borderedProminent)
                .disabled(isSavingCategory)
                .font(.caption2)
        } else {
            Button(option.label, action: action)
                .buttonStyle(.bordered)
                .disabled(isSavingCategory)
                .font(.caption2)
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
