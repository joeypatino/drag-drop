//
//  SceneDelegate.swift
//  DragDropDemo
//

import UIKit
import SwiftUI

/// The storyboard named by UISceneStoryboardFile populates `window` itself,
/// so there is nothing to construct here.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options: UIScene.ConnectionOptions) {
        // Defaults to nil, which renders black wherever no view covers it.
        window?.backgroundColor = .systemBackground

        // The SwiftUI integration harness. A hosting controller as the root is
        // what a SwiftUI app's window has, and it is the host the library
        // meets there. The storyboard's root is simply replaced.
        if let configuration = HarnessConfiguration.requested {
            window?.rootViewController = UIHostingController(rootView: HarnessRoot(configuration: configuration))
        }
    }
}
