import UIKit
import CoreData
import AppMetricaCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        CoreDataTransformers.register()
        
        AnalyticsService.activate()
        
        print("✅ Трансформеры зарегистрированы")
        return true
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CoreData")

        container.loadPersistentStores(completionHandler: {(storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Не удалось загрузить хранилище: \(error), \(error.userInfo)")
            }else {
                print("✅ База данных загружена")
            }
        })
        return container
    }()

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {

        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
  
    }
}

