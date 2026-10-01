import UIKit
import Capacitor
import StoreKit

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
