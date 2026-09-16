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
        guard let deviceId = payload["deviceId"] as? String else { return }
        if isPaired {
            // 既にペアリング済みの状態へペアリング情報が再度届いた場合
            // （再インストール後の再送・ユーザーの再ペアリング操作の重複等）。
            // 従来はここで何もせず黙って抜けていたため、iPhone側の
            // waitForPairingAck（watch_pairing_service.dart）が必ず
            // タイムアウトし、実際には何も失敗していないのに「ペアリングを
            // 確認できませんでした」という誤解を招く表示になっていた。
            sendPairingAck(deviceId: deviceId, succeeded: true)
            return
        }
        guard
            let customToken = payload["customToken"] as? String,
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
                sendPairingAck(deviceId: deviceId, succeeded: true)
            } catch {
                await MainActor.run {
                    self.lastError = "\(error)"
                }
                sendPairingAck(deviceId: deviceId, succeeded: false, error: "\(error)")
            }
        }
    }

    // iPhone側(watch_pairing_service.dart)はペアリング情報の送信直後、実際に
    // Watchでトークン交換まで完了したかを確認しないまま「ペアリング成功」を
    // 表示していた。Watchアプリが即座にフォアグラウンドでない・Bluetoothが
    // 不安定・customTokenのTTL切れ等でここが失敗しても、iPhone側には何も
    // 伝わらず、ユーザーは失敗に気づく手段が無かった。ここで結果をiPhoneへ
    // 明示的に返す。到達可能ならsendMessageで即時に、そうでなくても
    // updateApplicationContextで後から確実に届くようにする（iPhone側は
    // watch_pairing_service.dartのwaitForPairingAckで両方を待ち受ける）。
    private func sendPairingAck(deviceId: String, succeeded: Bool, error: String? = nil) {
        var payload: [String: Any] = ["pairingAckDeviceId": deviceId, "pairingSucceeded": succeeded]
        if let error { payload["pairingError"] = error }

        let session = WCSession.default
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        }
        try? session.updateApplicationContext(payload)
    }
}
