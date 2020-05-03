import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)

            let session = Session.createStore()

            window.rootViewController = UIHostingController(
                rootView: Home.view().environmentObject(session)
            )
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}
