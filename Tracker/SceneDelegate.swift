//
//  SceneDelegate.swift
//  Tracker
//
//  Created by Timofei Kirichenko on 13.01.2026.
//

import UIKit
import CoreData

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        //1 scene
        guard let scene = (scene as? UIWindowScene) else { return }
        configureWindowScene(with: scene)
    }
    
    private func configureWindowScene(with scene: UIWindowScene) {
        let window = UIWindow(windowScene: scene)
        
        let tabBarController = TabBarController()
        
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        self.window = window
      
    }

}

