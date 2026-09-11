//
//  SceneDelegate.swift
//  DragDropDemo
//

import UIKit

/// The storyboard named by UISceneStoryboardFile populates `window` itself,
/// so there is nothing to construct here.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options: UIScene.ConnectionOptions) {
        // Defaults to nil, which renders black wherever no view covers it.
        window?.backgroundColor = .systemBackground
    }
}
