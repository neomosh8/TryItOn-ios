import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    let authManager = AuthManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Run shared container diagnostics
        SharedContainer.shared.diagnoseAndFix()
        
        return true
    }
}
