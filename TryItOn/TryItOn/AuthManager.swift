import SwiftUI
import Combine
import os.log
import AuthenticationServices
import GoogleSignIn


class AuthManager: NSObject, ObservableObject {
    // Published properties
    @Published var isAuthenticated = false
    @Published var username: String = ""
    @Published var isPro: Bool = false
    @Published var profileImage: UIImage?
    @Published var email: String = ""
    @Published var authProvider: AuthProvider = .custom
    
    // Property for Apple Sign In
    private var currentNonce: String?
    
    enum AuthProvider: String, Codable {
        case custom
        case google
        case apple
    }
    
    // Check for saved login credentials
    func checkSavedLogin() {
        appLogger.log("Checking for saved login")
        
        // Check standard UserDefaults
        if let username = UserDefaults.standard.string(forKey: "username") {
            appLogger.log("Found username in standard UserDefaults: \(username)")
            self.username = username
            self.isPro = UserDefaults.standard.bool(forKey: "isPro")
            self.isAuthenticated = true
            
            // Load additional user info
            if let providerString = UserDefaults.standard.string(forKey: "authProvider"),
               let provider = AuthProvider(rawValue: providerString) {
                self.authProvider = provider
            }
            
            self.email = UserDefaults.standard.string(forKey: "email") ?? ""
            
            // Load profile image if available
            if let imageData = UserDefaults.standard.data(forKey: "profileImage") {
                self.profileImage = UIImage(data: imageData)
            }
            
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
    func updateFromSubscriptionManager(_ isSubscribed: Bool) {
        if isSubscribed != self.isPro {
            self.isPro = isSubscribed
            UserDefaults.standard.set(isSubscribed, forKey: "isPro")
            
            // Update shared container
            let userDefaults = UserDefaults(suiteName: "group.com.neocore.tech.TryItOn")
            userDefaults?.set(isSubscribed, forKey: "isPro")
            userDefaults?.synchronize()
        }
    }
    func login(username: String, isPro: Bool) {
        appLogger.log("Logging in with username: \(username), isPro: \(isPro)")
        self.username = username
        self.isPro = isPro
        self.authProvider = .custom
        
        // Create user on the server
        let url = URL(string: "\(APIConfig.baseURL)/users/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Fix the JSON encoding issue
        struct UserData: Codable {
            let username: String
            let is_pro: Bool
            let auth_provider: String
            let email: String?
        }
        
        let userData = UserData(
            username: username,
            is_pro: isPro,
            auth_provider: "custom",
            email: nil
        )
        
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
                UserDefaults.standard.set("custom", forKey: "authProvider")
                
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
    
    func loginWithGoogle() {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            appLogger.error("No root view controller found for Google Sign In")
            return
        }
        
        // Configure GIDSignIn
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: "172249664383-g5nivsbi979cl6e9kij2p29a5ag17307.apps.googleusercontent.com"
        )
        
        // Start the sign-in flow
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                appLogger.error("Google Sign In error: \(error.localizedDescription)")
                return
            }
            
            guard let user = result?.user else {
                appLogger.error("No user data returned from Google Sign In")
                return
            }
            
            let username = user.profile?.name ?? "GoogleUser"
            let email = user.profile?.email ?? ""
            
            // Get profile image if available
            if let profilePicURL = user.profile?.imageURL(withDimension: 200) {
                URLSession.shared.dataTask(with: profilePicURL) { data, response, error in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.profileImage = image
                            UserDefaults.standard.set(data, forKey: "profileImage")
                        }
                    }
                }.resume()
            }
            
            // Save credentials
            self.username = username
            self.email = email
            self.isPro = false  // Default to non-pro for Google users
            self.authProvider = .google
            
            // Save to UserDefaults
            UserDefaults.standard.set(username, forKey: "username")
            UserDefaults.standard.set(false, forKey: "isPro")
            UserDefaults.standard.set("google", forKey: "authProvider")
            UserDefaults.standard.set(email, forKey: "email")
            
            // Save to shared container
            let userDefaults = UserDefaults(suiteName: "group.com.neocore.tech.TryItOn")
            userDefaults?.set(username, forKey: "username")
            userDefaults?.set(false, forKey: "isPro")
            userDefaults?.synchronize()
            
            // Register with the server
            self.registerWithServer(
                username: username,
                isPro: false,
                provider: "google",
                email: email
            )
            
            self.isAuthenticated = true
        }
    }
    
    func loginWithApple() {
        // Generate a random nonce for Apple Sign In
        let nonce = generateNonce()
        currentNonce = nonce
        
        // Configure Apple Sign In request
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = nonce
        
        // Create and present Apple Sign In controller
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    private func registerWithServer(username: String, isPro: Bool, provider: String, email: String?) {
        let url = URL(string: "\(APIConfig.baseURL)/users/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        struct UserData: Codable {
            let username: String
            let is_pro: Bool
            let auth_provider: String
            let email: String?
        }
        
        let userData = UserData(
            username: username,
            is_pro: isPro,
            auth_provider: provider,
            email: email
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(userData)
        } catch {
            appLogger.error("Error encoding user data: \(error.localizedDescription)")
            return
        }
        
        appLogger.log("Registering \(provider) user with server")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                appLogger.error("Server registration error: \(error.localizedDescription)")
                return
            }
            
            let httpResponse = response as? HTTPURLResponse
            appLogger.log("Registration response status: \(httpResponse?.statusCode ?? 0)")
            
            // Parse any additional server response if needed
        }.resume()
    }
    
    func logout() {
        appLogger.log("Logging out user: \(self.username)")
        
        // Handle sign out based on provider
        switch authProvider {
        case .google:
            GIDSignIn.sharedInstance.signOut()
        case .apple:
            // Apple doesn't have a sign-out method, just clear local data
            break
        case .custom:
            // No additional steps needed
            break
        }
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "isPro")
        UserDefaults.standard.removeObject(forKey: "authProvider")
        UserDefaults.standard.removeObject(forKey: "email")
        UserDefaults.standard.removeObject(forKey: "profileImage")
        
        // Clear shared container
        let userDefaults = UserDefaults(suiteName: "group.com.neocore.tech.TryItOn")
        userDefaults?.removeObject(forKey: "username")
        userDefaults?.removeObject(forKey: "isPro")
        userDefaults?.synchronize()
        
        // Reset properties
        username = ""
        isPro = false
        email = ""
        profileImage = nil
        authProvider = .custom
        isAuthenticated = false
    }
    
    // Helper function to generate a random nonce for Apple Sign In
    private func generateNonce(length: Int = 32) -> String {
        let charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._"
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    let index = charset.index(charset.startIndex, offsetBy: Int(random))
                    result.append(charset[index])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    func updateSubscriptionStatus(isActive: Bool) {
        self.isPro = isActive
        
        // Save to UserDefaults
        UserDefaults.standard.set(isActive, forKey: "isPro")
        
        // Save to shared container
        let userDefaults = UserDefaults(suiteName: "group.com.neocore.tech.TryItOn")
        userDefaults?.set(isActive, forKey: "isPro")
        userDefaults?.synchronize()
        
        // Register update with server
        registerWithServer(
            username: self.username,
            isPro: isActive,
            provider: self.authProvider.rawValue,
            email: self.email
        )
    }
}

// MARK: - Apple Sign In Delegates
extension AuthManager: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first!
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            appLogger.error("Unable to retrieve Apple ID credentials")
            return
        }
        
        // Extract user info
        let userIdentifier = appleIDCredential.user
        let fullName = appleIDCredential.fullName
        let email = appleIDCredential.email
        
        // Create a username from the full name or use the Apple ID
        var username = "AppleUser"
        if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
            username = "\(givenName)\(familyName)"
        } else if let nameComps = fullName?.givenName {
            username = nameComps
        }
        
        // Save credentials
        self.username = username
        self.email = email ?? ""
        self.isPro = false  // Default to non-pro for Apple users
        self.authProvider = .apple
        
        // Save to UserDefaults
        UserDefaults.standard.set(username, forKey: "username")
        UserDefaults.standard.set(false, forKey: "isPro")
        UserDefaults.standard.set("apple", forKey: "authProvider")
        UserDefaults.standard.set(email, forKey: "email")
        UserDefaults.standard.set(userIdentifier, forKey: "appleUserID")
        
        // Save to shared container
        let userDefaults = UserDefaults(suiteName: "group.com.neocore.tech.TryItOn")
        userDefaults?.set(username, forKey: "username")
        userDefaults?.set(false, forKey: "isPro")
        userDefaults?.synchronize()
        
        // Register with the server
        registerWithServer(
            username: username,
            isPro: false,
            provider: "apple",
            email: email
        )
        
        self.isAuthenticated = true
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        appLogger.error("Apple Sign In error: \(error.localizedDescription)")
    }
}

