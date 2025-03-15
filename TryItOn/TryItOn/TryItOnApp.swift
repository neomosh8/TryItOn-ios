// TryItOn App
// Main App Structure

import SwiftUI
import Combine

@main
struct TryItOnApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var dataManager = DataManager()
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
                    .environmentObject(dataManager)
                    .onAppear {
                        dataManager.fetchTemplates()
                        dataManager.fetchResults()
                    }
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}

// MARK: - Authentication and User Management

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var username: String = ""
    @Published var isPro: Bool = false
    
    func login(username: String, isPro: Bool) {
        self.username = username
        self.isPro = isPro
        
        // Create user on the server
        let url = URL(string: "\(APIConfig.baseURL)/users/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let userData = ["username": username, "is_pro": isPro]
        request.httpBody = try? JSONEncoder().encode(userData)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Login error: \(error)")
                    return
                }
                
                // Save credentials locally
                UserDefaults.standard.set(username, forKey: "username")
                UserDefaults.standard.set(isPro, forKey: "isPro")
                self.isAuthenticated = true
            }
        }.resume()
    }
    
    func checkSavedLogin() {
        if let username = UserDefaults.standard.string(forKey: "username") {
            self.username = username
            self.isPro = UserDefaults.standard.bool(forKey: "isPro")
            self.isAuthenticated = true
        }
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "isPro")
        username = ""
        isPro = false
        isAuthenticated = false
    }
}



// MARK: - Views



