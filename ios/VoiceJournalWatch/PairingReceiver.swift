import Foundation
import WatchConnectivity

/// iPhone側（Flutterアプリ、watch_connectivityパッケージ経由）から
/// WatchConnectivityのtransferUserInfoで中継されるペアリング情報
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
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        guard
            let customToken = userInfo["customToken"] as? String,
            let deviceId = userInfo["deviceId"] as? String,
            let deviceSecret = userInfo["deviceSecret"] as? String
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
