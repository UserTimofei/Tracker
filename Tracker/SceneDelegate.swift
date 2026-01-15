//
//  SceneDelegate.swift
//  Tracker
//
//  Created by Timofei Kirichenko on 13.01.2026.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        //1 scene
        guard let scene = (scene as? UIWindowScene) else { return }
        
        //2 init window
        self.window = UIWindow(windowScene: scene)
        //3 root controller - главный контроллер
//        self.window?.rootViewController = HomeViewController()
        self.window?.rootViewController = TabBarController()
        self.window?.makeKeyAndVisible()
        
    }

}

