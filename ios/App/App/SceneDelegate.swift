import UIKit
import Capacitor
import StoreKit
import GameKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = MainViewController()
        window?.makeKeyAndVisible()

        SceneDelegateProxy.shared.scene(scene, willConnectTo: session, options: connectionOptions)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        SceneDelegateProxy.shared.scene(scene, openURLContexts: URLContexts)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        SceneDelegateProxy.shared.scene(scene, continue: userActivity)
    }
}

/// Hosts the game and registers the app's own plugins.
class MainViewController: CAPBridgeViewController {
    override func capacitorDidLoad() {
        bridge?.registerPluginInstance(StorePlugin())
        bridge?.registerPluginInstance(GameCenterPlugin())
    }
}

/// The one-time "Remove Ads" purchase, on StoreKit 2. JS sees it as Capacitor.Plugins.Store.
@objc(StorePlugin)
public class StorePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "StorePlugin"
    public let jsName = "Store"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "product", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "purchase", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "owned", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "restore", returnType: CAPPluginReturnPromise)
    ]
    private var updates: Task<Void, Never>?

    override public func load() {
        // purchases finished outside the app (Ask to Buy, refunds, other devices) arrive here
        updates = Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let t) = result else { continue }
                await t.finish()
                self?.notifyListeners("entitlement", data: ["id": t.productID, "owned": t.revocationDate == nil])
            }
        }
    }

    deinit { updates?.cancel() }

    private func isOwned(_ id: String) async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.productID == id, t.revocationDate == nil { return true }
        }
        return false
    }

    @objc func product(_ call: CAPPluginCall) {
        guard let id = call.getString("id") else { return call.reject("id required") }
        Task {
            do {
                guard let p = try await Product.products(for: [id]).first else { return call.resolve(["available": false]) }
                call.resolve(["available": true, "price": p.displayPrice, "title": p.displayName])
            } catch {
                call.resolve(["available": false, "error": error.localizedDescription])
            }
        }
    }

    @objc func purchase(_ call: CAPPluginCall) {
        guard let id = call.getString("id") else { return call.reject("id required") }
        Task {
            do {
                guard let p = try await Product.products(for: [id]).first else { return call.reject("This purchase isn't available yet.") }
                switch try await p.purchase() {
                case .success(let verification):
                    guard case .verified(let t) = verification else { return call.resolve(["owned": false]) }
                    await t.finish()
                    call.resolve(["owned": true])
                case .userCancelled:
                    call.resolve(["owned": false, "cancelled": true])
                case .pending:
                    call.resolve(["owned": false, "pending": true])
                @unknown default:
                    call.resolve(["owned": false])
                }
            } catch {
                call.reject(error.localizedDescription)
            }
        }
    }

    @objc func owned(_ call: CAPPluginCall) {
        guard let id = call.getString("id") else { return call.reject("id required") }
        Task { call.resolve(["owned": await self.isOwned(id)]) }
    }

    @objc func restore(_ call: CAPPluginCall) {
        guard let id = call.getString("id") else { return call.reject("id required") }
        Task {
            try? await AppStore.sync()
            call.resolve(["owned": await self.isOwned(id)])
        }
    }
}

/// Game Center sign-in, score submission and the leaderboard sheet. JS sees it as Capacitor.Plugins.GameCenter.
@objc(GameCenterPlugin)
public class GameCenterPlugin: CAPPlugin, CAPBridgedPlugin, GKGameCenterControllerDelegate {
    public let identifier = "GameCenterPlugin"
    public let jsName = "GameCenter"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "auth", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "submit", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "show", returnType: CAPPluginReturnPromise)
    ]

    @objc func auth(_ call: CAPPluginCall) {
        let player = GKLocalPlayer.local
        if player.isAuthenticated { return call.resolve(["authenticated": true]) }
        var answered = false
        player.authenticateHandler = { [weak self] vc, _ in
            // Game Center's own sign-in sheet appears only if the player isn't signed in on the device
            if let vc = vc {
                DispatchQueue.main.async { self?.bridge?.viewController?.present(vc, animated: true) }
                return
            }
            if !answered { answered = true; call.resolve(["authenticated": GKLocalPlayer.local.isAuthenticated]) }
        }
    }

    @objc func submit(_ call: CAPPluginCall) {
        guard let id = call.getString("id"), let score = call.getInt("score") else { return call.reject("id and score required") }
        guard GKLocalPlayer.local.isAuthenticated else { return call.reject("not signed in") }
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [id]) { error in
            if let error = error { call.reject(error.localizedDescription) } else { call.resolve() }
        }
    }

    @objc func show(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            let vc = GKGameCenterViewController(state: .leaderboards)
            vc.gameCenterDelegate = self
            self.bridge?.viewController?.present(vc, animated: true)
            call.resolve()
        }
    }

    public func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
