import SwiftUI

struct ContentView: View {
    @StateObject private var pairing = PairingReceiver.shared
    @StateObject private var recorder = AudioRecorder()
    @State private var statusMessage: String?
    @State private var isUploading = false

    var body: some View {
        VStack(spacing: 12) {
            if !pairing.isPaired {
                Text("iPhoneアプリでペアリングしてください")
                    .multilineTextAlignment(.center)
                    .font(.footnote)
            } else {
                recordButton
                if let message = statusMessage {
                    Text(message)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
        .onAppear {
            recorder.requestPermissionIfNeeded { _ in }
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
        .disabled(isUploading)
    }

    private func toggleRecording() {
        if recorder.isRecording {
            guard let url = recorder.stop() else { return }
            statusMessage = "アップロード中…"
            isUploading = true
            Task {
                do {
                    let result = try await VoiceMemoUploader.upload(audioFileURL: url)
                    await MainActor.run {
                        statusMessage = result.summary
                        isUploading = false
                    }
                } catch {
                    await MainActor.run {
                        statusMessage = "エラー: \(error)"
                        isUploading = false
                    }
                }
            }
        } else {
            statusMessage = nil
            recorder.start()
        }
    }
}
