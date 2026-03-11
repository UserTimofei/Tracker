import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let scene = (scene as? UIWindowScene) else { return }
        configureWindowScene(with: scene)
    }
    
    private func configureWindowScene(with scene: UIWindowScene) {
        let window = UIWindow(windowScene: scene)
        
        let onboardingWasShown = UserDefaults.standard.bool(forKey: "onboardingWasShown")
        
        if onboardingWasShown {
            window.rootViewController = TabBarController()
        } else {
            window.rootViewController = OnboardingViewController()
        }
        
        window.makeKeyAndVisible()
        self.window = window
      
    }

}

