import Foundation
import WatchConnectivity

/// iPhone側（Flutterアプリ、watch_connectivityパッケージ経由）から
/// WatchConnectivityのupdateApplicationContext（このパッケージは
/// transferUserInfoを公開していないため）で中継されるペアリング情報
/// （customToken/deviceId/deviceSecret）を受け取り、FirebaseAuthClientで
/// Watch専用のrefreshTokenに交換してKeychainへ保存する。
final class PairingReceiver: NSObject, ObservableObject {
    static let shared = PairingReceiver()

    @Published var isPaired: Bool = KeychainStore.isPaired
    @Published var lastError: String?

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
}

extension PairingReceiver: WCSessionDelegate {
    // didReceiveApplicationContextは新着データにのみ反応するedge-triggeredな
    // コールバックで、iPhone側が先にペアリングを送信し、Watch側アプリが後から
    // 起動された場合（実際によくある順序）は一度も呼ばれない。activate完了時に
    // 保留中の最新コンテキストをsession.receivedApplicationContextから
    // 明示的に読み直すことで、この取りこぼしを防ぐ。
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated else { return }
        handlePairingPayload(session.receivedApplicationContext)
    }

    // iPhone側（watch_pairing_service.dart）は実際にはtransferUserInfoではなく
    // updateApplicationContextでペアリング情報を送っている（watch_connectivity
    // パッケージがtransferUserInfoを公開していないため）。didReceiveUserInfoしか
    // 実装していないとこの中継が届かず無言で失敗するため、両方の経路に対応する。
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        handlePairingPayload(userInfo)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handlePairingPayload(applicationContext)
    }

    private func handlePairingPayload(_ payload: [String: Any]) {
        guard !isPaired else { return }
        guard
            let customToken = payload["customToken"] as? String,
            let deviceId = payload["deviceId"] as? String,
            let deviceSecret = payload["deviceSecret"] as? String
        else { return }

        Task {
            do {
                try await FirebaseAuthClient.shared.completePairing(
                    customToken: customToken,
                    deviceId: deviceId,
                    deviceSecret: deviceSecret
                )
                await MainActor.run {
                    self.isPaired = true
                    self.lastError = nil
                }
            } catch {
                await MainActor.run {
                    self.lastError = "\(error)"
                }
            }
        }
    }
}
