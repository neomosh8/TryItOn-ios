import Foundation
import os.log

// Create a logger for the shared container
let containerLogger = Logger(subsystem: "neocore.TryItOn", category: "SharedContainer")

class SharedContainer {
    static let shared = SharedContainer()
    
    private let containerIdentifier = "group.com.neocore.tech.TryItOn"
    private var userDefaults: UserDefaults?
    
    private init() {
        userDefaults = UserDefaults(suiteName: containerIdentifier)
        if userDefaults == nil {
            containerLogger.error("Failed to access shared container with ID: \(self.containerIdentifier)")
        } else {
            containerLogger.log("Successfully accessed shared container")
        }
    }
    
    func diagnoseAndFix() {
        containerLogger.log("Diagnosing shared container")
        
        // Check if app-specific UserDefaults has credentials
        let username = UserDefaults.standard.string(forKey: "username")
        let isPro = UserDefaults.standard.bool(forKey: "isPro")
        
        // Check if shared container has credentials
        let sharedUsername = userDefaults?.string(forKey: "username")
        
        if let username = username {
            containerLogger.log("App UserDefaults has username: \(username)")
            
            if let sharedUsername = sharedUsername {
                containerLogger.log("Shared container has username: \(sharedUsername)")
                
                // Check if they match
                if username != sharedUsername {
                    containerLogger.error("Username mismatch! App: \(username), Shared: \(sharedUsername)")
                    fixCredentials(username: username, isPro: isPro)
                }
            } else {
                containerLogger.error("Shared container missing username")
                fixCredentials(username: username, isPro: isPro)
            }
        } else {
            containerLogger.log("No username in App UserDefaults")
            
            if let sharedUsername = sharedUsername {
                containerLogger.log("But shared container has username: \(sharedUsername)")
                // This is unusual - shared has data but app doesn't
                
                // Copy from shared to app
                UserDefaults.standard.set(sharedUsername, forKey: "username")
                let sharedIsPro = userDefaults?.bool(forKey: "isPro") ?? false
                UserDefaults.standard.set(sharedIsPro, forKey: "isPro")
                containerLogger.log("Copied credentials from shared to app")
            } else {
                containerLogger.log("Neither app nor shared container have credentials")
            }
        }
    }
    
    private func fixCredentials(username: String, isPro: Bool) {
        containerLogger.log("Fixing credentials in shared container")
        userDefaults?.set(username, forKey: "username")
        userDefaults?.set(isPro, forKey: "isPro")
        userDefaults?.synchronize()
        
        // Verify fix
        if let fixedUsername = userDefaults?.string(forKey: "username") {
            containerLogger.log("Fix verified: Shared container now has username: \(fixedUsername)")
        } else {
            containerLogger.error("Fix FAILED: Still can't write to shared container")
        }
    }
}
