// TryItOn App
// Main App Structure

import SwiftUI
import Combine
import os.log

// Create a logger for debugging
let appLogger = Logger(subsystem: "neocore.TryItOn", category: "AppAuthentication")

@main
struct TryItOnApp: App {
    // Create a shared instance of AuthManager and DataManager
    @StateObject private var authManager = AuthManager()
    @StateObject private var dataManager = DataManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(dataManager)
                .onAppear {
                    // Debug the shared container on app launch
                    let userDefaults = UserDefaults(suiteName: "group.com.neocore.tech.TryItOn")
                    if let username = userDefaults?.string(forKey: "username") {
                        appLogger.log("App launch - Shared container has username: \(username)")
                    } else {
                        appLogger.log("App launch - Shared container has NO username")
                    }
                }
        }
    }
}

// Wrapper view to handle app initialization and state
struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        ZStack {
            if authManager.isAuthenticated {
                MainTabView()
                    .onAppear {
                        dataManager.fetchTemplates()
                        dataManager.fetchResults()
                    }
            } else {
                LoginView()
            }
        }
        .onAppear {
            // Connect managers and check for saved login
            connectManagers()
            authManager.checkSavedLogin()
        }
    }
    
    private func connectManagers() {
        dataManager.authManager = authManager
    }
}


// MARK: - API Configuration
struct APIConfig {
    // For simulator
    static let baseURL = "https://tryiton.shopping"
//    static let baseURL = "http://localhost:8000"
    
    // OR if using a physical device (use your computer's IP address)
    // static let baseURL = "http://192.168.1.123:8000"
    
    static func authHeader(username: String) -> [String: String] {
        return ["username": username]
    }
}
