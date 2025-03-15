// TryItOn App
// Main App Structure

import SwiftUI
import Combine

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
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var username: String = ""
    @Published var isPro: Bool = false
    
    // Check for saved login credentials
    func checkSavedLogin() {
        if let username = UserDefaults.standard.string(forKey: "username") {
            self.username = username
            self.isPro = UserDefaults.standard.bool(forKey: "isPro")
            self.isAuthenticated = true
        }
    }
    
    func login(username: String, isPro: Bool) {
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
            print("Error encoding user data: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Login error: \(error)")
                    return
                }
                
                // Save credentials in both locations
                UserDefaults.standard.set(username, forKey: "username")
                UserDefaults.standard.set(isPro, forKey: "isPro")
                
                // Also save to App Group storage for the share extension
                let userDefaults = UserDefaults(suiteName: "group.com.neocore.tech.TryItOn")
                userDefaults?.set(username, forKey: "username")
                userDefaults?.set(isPro, forKey: "isPro")
                userDefaults?.synchronize() // Add this line

                self.isAuthenticated = true
            }
        }.resume()
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "isPro")
        
        // Also clear from App Group storage
        let userDefaults = UserDefaults(suiteName: "group.com.neocore.tech.TryItOn")

        userDefaults?.removeObject(forKey: "username")
        userDefaults?.removeObject(forKey: "isPro")
        userDefaults?.synchronize() // Add this line

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
