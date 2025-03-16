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

// MARK: - Authentication and User Management
// MARK: - Authentication and User Management
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var username: String = ""
    @Published var isPro: Bool = false
    
    // Check for saved login credentials
    func checkSavedLogin() {
        appLogger.log("Checking for saved login")
        
        // Check standard UserDefaults
        if let username = UserDefaults.standard.string(forKey: "username") {
            appLogger.log("Found username in standard UserDefaults: \(username)")
            self.username = username
            self.isPro = UserDefaults.standard.bool(forKey: "isPro")
            self.isAuthenticated = true
            
            // Verify shared container has the data too
            let userDefaults = UserDefaults(suiteName: "group.com.neocore.tech.TryItOn")
            if let sharedUsername = userDefaults?.string(forKey: "username") {
                appLogger.log("Shared container also has username: \(sharedUsername)")
            } else {
                appLogger.log("WARNING: Username not found in shared container, fixing it now")
                userDefaults?.set(username, forKey: "username")
                userDefaults?.set(self.isPro, forKey: "isPro")
                userDefaults?.synchronize()
            }
        } else {
            appLogger.log("No username found in UserDefaults")
        }
    }
    
    func login(username: String, isPro: Bool) {
        appLogger.log("Logging in with username: \(username), isPro: \(isPro)")
        self.username = username
        self.isPro = isPro
        
        // Create user on the server
        let url = URL(string: "\(APIConfig.baseURL)/users/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Fix the JSON encoding issue
        struct UserData: Codable {
            let username: String
            let is_pro: Bool
        }
        
        let userData = UserData(username: username, is_pro: isPro)
        
        do {
            request.httpBody = try JSONEncoder().encode(userData)
        } catch {
            appLogger.error("Error encoding user data: \(error.localizedDescription)")
            return
        }
        
        appLogger.log("Sending login request to server")
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    appLogger.error("Login error: \(error.localizedDescription)")
                    return
                }
                
                let httpResponse = response as? HTTPURLResponse
                appLogger.log("Login response status: \(httpResponse?.statusCode ?? 0)")
                
                // Save credentials in standard UserDefaults
                appLogger.log("Saving to standard UserDefaults")
                UserDefaults.standard.set(username, forKey: "username")
                UserDefaults.standard.set(isPro, forKey: "isPro")
                
                // Save to App Group storage for the share extension
                appLogger.log("Saving to shared container")
                let userDefaults = UserDefaults(suiteName: "group.com.neocore.tech.TryItOn")
                userDefaults?.set(username, forKey: "username")
                userDefaults?.set(isPro, forKey: "isPro")
                userDefaults?.synchronize()
                
                // Verify the data was saved correctly
                let savedUsername = userDefaults?.string(forKey: "username")
                appLogger.log("Verified shared container now has username: \(savedUsername ?? "nil")")
                
                self?.isAuthenticated = true
            }
        }.resume()
    }
    
    func logout() {
        appLogger.log("Logging out user: \(self.username)")
        
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "isPro")
        
        // Also clear from App Group storage
        let userDefaults = UserDefaults(suiteName: "group.com.neocore.tech.TryItOn")
        userDefaults?.removeObject(forKey: "username")
        userDefaults?.removeObject(forKey: "isPro")
        userDefaults?.synchronize()
        
        // Verify the data was cleared correctly
        if let username = userDefaults?.string(forKey: "username") {
            appLogger.error("Failed to clear username from shared container: \(username)")
        } else {
            appLogger.log("Successfully cleared username from shared container")
        }

        username = ""
        isPro = false
        isAuthenticated = false
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
