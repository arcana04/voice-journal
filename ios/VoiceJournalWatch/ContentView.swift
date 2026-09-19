import SwiftUI

/// 録音〜保存の画面状態。録音停止と同時にAIの分類結果をそのままFirestoreへ
/// 保存してしまう(データを失わないことを優先)。reviewingの画面はその後、
/// 項目ごとに分類の選び直し・テキストの編集ができる一覧を表示し、
/// 「保存して閉じる」を押すとその時点の内容で上書きする。iPhoneが無くても
/// Watch単体で仕分け・訂正が完結する（アプリの「Watch単体で完結する」という
/// コンセプトに合わせている）。
private enum FlowState {
    case idle
    case uploading
    case reviewing(ReviewContext)
    case saved
    /// retryが非nilの場合、その場でアップロードをやり直せる
    /// (音声ファイルは強制終了からの復元用マーカーがEntryStore.save成功まで
    /// 消えないため、ここで「閉じる」を押しても失われない)。
    case error(message: String, retry: PendingUpload?)
    /// 前回、録音は完了(またはアップロード成功の可能性あり)したのに
    /// EntryStore.saveまで届かなかった録音ファイルが見つかった状態。
    case orphanFound(URL)
}

private struct ReviewContext {
    let summary: String
    let comfortMessage: String?
    let emotion: String?
    let createdAt: Date
    let entryId: String
}

private struct PendingUpload {
    let audioURL: URL
    let allowedCategories: Set<EntryCategory>
}

struct ContentView: View {
    @StateObject private var pairing = PairingReceiver.shared
    @StateObject private var recorder = AudioRecorder()
    @State private var flow: FlowState = .idle
    @State private var draftItems: [DraftItem] = []
    @State private var isSaving = false
    /// 録音前の「何について話すか」の絞り込み。iPhone側(home_screen.dartの
    /// _selectedCategories)と同じルール: 常に1つ以上は選択された状態を保ち、
    /// 使い終えたら次の録音のために全選択へ戻す。
    @State private var selectedCategories: Set<EntryCategory> = Set(EntryCategory.allCases)

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
            checkForOrphanRecording()
        }
        .onChange(of: recorder.interruptedRecordingURL) { newValue in
            guard let url = newValue else { return }
            recorder.interruptedRecordingURL = nil
            let allowedForThisUpload = selectedCategories
            selectedCategories = Set(EntryCategory.allCases)
            flow = .error(
                message: "録音が中断されました。ここまでの内容を送信できます。",
                retry: PendingUpload(audioURL: url, allowedCategories: allowedForThisUpload)
            )
        }
    }

    /// アップロード未完了のまま残っている録音ファイル(前回の強制終了・
    /// クラッシュ等)があれば、通常の録音操作より先にその処理を促す。
    private func checkForOrphanRecording() {
        guard case .idle = flow, !recorder.isRecording else { return }
        if let url = AudioRecorder.recoverableRecordingURL {
            flow = .orphanFound(url)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch flow {
        case .idle:
            if !recorder.isRecording {
                categoryFilterRow
            }
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
        case .reviewing(let context):
            reviewView(context: context)
        case .saved:
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.green)
            Text("保存できました")
                .font(.footnote)
        case .error(let message, let retry):
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.caption2)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
            if let retry {
                Button("送信する") {
                    performUpload(url: retry.audioURL, allowedCategories: retry.allowedCategories)
                }
                .buttonStyle(.borderedProminent)
            }
            Button("閉じる") { flow = .idle }
                .buttonStyle(.bordered)
        case .orphanFound(let url):
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundColor(.orange)
            Text("前回未送信の録音が見つかりました")
                .font(.caption2)
                .multilineTextAlignment(.center)
            Button("送信する") {
                performUpload(url: url, allowedCategories: Set(EntryCategory.allCases))
            }
            .buttonStyle(.borderedProminent)
            Button("破棄する") { discardOrphan(url: url) }
                .buttonStyle(.bordered)
                .tint(.red)
        }
    }

    private var elapsedLabel: String {
        let seconds = recorder.elapsedSeconds
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    /// 「何について話すか」を録音前に絞り込むチップ。iPhone側の
    /// _CategoryFilterRow(home_screen.dart)に相当する、Watch向けの
    /// アイコンのみの小さいトグルボタン版。
    private var categoryFilterRow: some View {
        HStack(spacing: 6) {
            ForEach(EntryCategory.allCases, id: \.self) { category in
                let isSelected = selectedCategories.contains(category)
                Button(action: { toggleCategory(category) }) {
                    Image(systemName: category.iconName)
                        .font(.footnote)
                        .foregroundColor(isSelected ? .white : .gray)
                        .frame(width: 34, height: 26)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// 少なくとも1つは選択された状態を保つ(iPhone側の_toggleCategoryと同じルール)。
    private func toggleCategory(_ category: EntryCategory) {
        if selectedCategories.contains(category) {
            if selectedCategories.count > 1 {
                selectedCategories.remove(category)
            }
        } else {
            selectedCategories.insert(category)
        }
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

    private func reviewView(context: ReviewContext) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("分類をタップで切替・内容を編集できます")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                if draftItems.isEmpty {
                    Text("項目がありません")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    ForEach($draftItems) { $item in
                        DraftItemRow(
                            item: $item,
                            onDelete: { draftItems.removeAll { $0.id == item.id } }
                        )
                    }
                }

                Button(action: { saveDraft(context: context) }) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("保存して閉じる")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(isSaving)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }
            .padding(.horizontal, 2)
        }
    }

    private func saveDraft(context: ReviewContext) {
        isSaving = true
        let items = draftItems
        Task {
            do {
                try await EntryStore.saveDraftItems(
                    items,
                    summary: context.summary,
                    comfortMessage: context.comfortMessage,
                    emotion: context.emotion,
                    createdAt: context.createdAt,
                    entryId: context.entryId
                )
                await MainActor.run {
                    isSaving = false
                    flow = .saved
                }
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                await MainActor.run {
                    if case .saved = flow {
                        flow = .idle
                    }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    // 元となる項目自体はrecordButton側のperformUploadで既にFirestoreへ
                    // 保存済み(データを失わないことを優先する設計)なので、ここでの失敗は
                    // 「編集内容の上書きに失敗した」だけであり、録音のアップロードとは
                    // 別物のため再試行ボタンは出さない(音声ファイルの再送は不要)。
                    flow = .error(message: "\(error)", retry: nil)
                }
            }
        }
    }

    private func toggleRecording() {
        if recorder.isRecording {
            guard let url = recorder.stop() else { return }
            // 今回の絞り込みをアップロードに使う分だけ確保してから、次の録音のために
            // チップを全選択へ戻す(iPhone側home_screen.dartの_toggleRecordingと同じ流れ)。
            let allowedForThisUpload = selectedCategories
            selectedCategories = Set(EntryCategory.allCases)
            performUpload(url: url, allowedCategories: allowedForThisUpload)
        } else {
            flow = .idle
            recorder.start()
        }
    }

    /// 録音済みファイルのアップロード〜初回保存。通常の録音停止直後、
    /// アップロード失敗後の再試行、中断された録音の送信、前回の未送信録音の
    /// 復元、いずれの場合もここを通す。
    private func performUpload(url: URL, allowedCategories: Set<EntryCategory>) {
        flow = .uploading
        Task {
            do {
                let result = try await VoiceMemoUploader.upload(
                    audioFileURL: url,
                    allowedCategories: allowedCategories
                )
                let createdAt = Date()
                let entryId = EntryStore.generateEntryId()
                // まずAIの分類結果をそのまま保存する(データを失わないことを優先)。
                // このあとの画面で編集しても、指を離すまでの間にアプリが落ちる等
                // しても記録自体は既に残っている。
                try await EntryStore.save(result: result, createdAt: createdAt, entryId: entryId)
                // ここまで来た時点でこの録音はFirestoreへ安全に残っているため、
                // 強制終了時の復元用マーカー(このURLを指しているものに限る)を消す。
                AudioRecorder.clearRecoverableRecording(matching: url, deleteFile: true)
                await MainActor.run {
                    draftItems = result.draftItems()
                    flow = .reviewing(
                        ReviewContext(
                            summary: result.summary,
                            comfortMessage: result.comfort_message,
                            emotion: result.emotion,
                            createdAt: createdAt,
                            entryId: entryId
                        )
                    )
                }
            } catch {
                await MainActor.run {
                    // ここで「閉じる」を選んでも、強制終了時の復元用マーカーは
                    // EntryStore.save成功まで消していないため、このファイルは
                    // 次回起動時にorphanFoundとして再度アップロードを促せる。
                    flow = .error(
                        message: "\(error)",
                        retry: PendingUpload(audioURL: url, allowedCategories: allowedCategories)
                    )
                }
            }
        }
    }

    private func discardOrphan(url: URL) {
        AudioRecorder.clearRecoverableRecording(matching: url, deleteFile: true)
        flow = .idle
    }
}

/// 分類の選び直し(タップで次の分類へ巡回)とテキスト編集(タップでWatchの
/// Scribble/ディクテーション/キーボード入力)ができる1項目分の行。ドラッグ
/// 操作はWatchの画面サイズでは操作精度が厳しいため、タップ操作で代替している。
/// (MenuもPickerもwatchOSで表示が崩れたため、単純な巡回ボタンに変更している)
private struct DraftItemRow: View {
    @Binding var item: DraftItem
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Button(action: { item.category = item.category.next }) {
                    Label(item.category.label, systemImage: item.category.iconName)
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                .buttonStyle(.bordered)
                .tint(.blue)

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }

            TextField("内容", text: $item.text, axis: .vertical)
                .font(.caption2)
                .lineLimit(1...4)
        }
        .padding(6)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(8)
    }
}
