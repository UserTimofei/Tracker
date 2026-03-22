import Foundation
import AppMetricaCore

struct AnalyticsService {
    
    private static let apiKey = "bfc0fe35-6a5b-482d-8fea-90ca9cf074c5"

    static func activate() {
        guard let configuration = AppMetricaConfiguration(apiKey: apiKey) else {
            print("❌ Ошибка конфигурации AppMetrica")
            return
        }

        AppMetrica.activate(with: configuration)
        print("✅ AppMetrica активирован")
    }
    static func report(event: String, params: [String: Any] = [:]) {
        AppMetrica.reportEvent(name: event, parameters: params) { (error: Error?) in
            if let error = error {
                print("❌ Ошибка: \(error)")
            } else {
                print("✅ Отправлено")
            }
        }
    }
}
