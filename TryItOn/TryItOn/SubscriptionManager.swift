import StoreKit
import Combine

enum SubscriptionTier: String, Identifiable, CaseIterable {
    case pro = "neocore.TryItOn.subscription.pro"
    
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .pro: return "TryItOn Pro"
        }
    }
}

// Custom error enum for subscription handling
enum StoreError: Error {
    case failedVerification
    case expiredSubscription
    case notEntitled
}

class SubscriptionManager: ObservableObject {
    // Published properties for UI binding
    @Published var products: [Product] = []
    @Published var purchasedSubscriptions: [Product] = []
    @Published var isSubscriptionActive = false
    @Published var isLoading = false
    @Published var error: String?
    
    // Store subscription expiration date
    @Published var expirationDate: Date?
    
    // Internal properties
    private var updateListenerTask: Task<Void, Error>?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        updateListenerTask = listenForTransactionUpdates()
        
        // Load products when initialized
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // Load available products from the App Store
    @MainActor
    func loadProducts() async {
        do {
            isLoading = true
            
            // Request products from the App Store
            let productIds = SubscriptionTier.allCases.map { $0.rawValue }
            let storeProducts = try await Product.products(for: productIds)
            
            products = storeProducts
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
    
    // Purchase a subscription
    @MainActor
    func purchase(_ product: Product) async throws {
        do {
            isLoading = true
            
            // Begin a purchase with StoreKit
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // The purchase was successful
                let transaction = try checkVerified(verification)
                await updateSubscriptionStatus()
                
                // Finish the transaction
                await transaction.finish()
                
                // Notify the server about the purchase
                notifyServer(status: true)
                
            case .userCancelled:
                // User cancelled the purchase
                break
                
            case .pending:
                // Purchase needs approval (e.g., from parent)
                break
                
            default:
                // Handle any other cases
                break
            }
            
            isLoading = false
        } catch {
            isLoading = false
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // Restore purchases
    @MainActor
    func restorePurchases() async {
        do {
            isLoading = true
            
            // Request the App Store to restore previous purchases
            try await AppStore.sync()
            
            // Update the subscription status
            await updateSubscriptionStatus()
            
            isLoading = false
        } catch {
            isLoading = false
            self.error = error.localizedDescription
        }
    }
    
    // Update the current subscription status
    @MainActor
    func updateSubscriptionStatus() async {
        // Get the most recent transaction for each subscription
        for tier in SubscriptionTier.allCases {
            do {
                // Fix: Properly unwrap the optional result
                if let result = try await Transaction.latest(for: tier.rawValue) {
                    // If we have a verified transaction, check its status
                    if let transaction = try? checkVerified(result) {
                        let isActive = transaction.revocationDate == nil &&
                                      !transaction.isUpgraded &&
                                      (transaction.expirationDate == nil || transaction.expirationDate! > Date())
                        
                        if isActive {
                            isSubscriptionActive = true
                            expirationDate = transaction.expirationDate
                            
                            // Update UserDefaults to reflect subscription status
                            UserDefaults.standard.set(true, forKey: "isPro")
                            
                            // Update shared container for extensions
                            let userDefaults = UserDefaults(suiteName: "group.com.neocore.tech.TryItOn")
                            userDefaults?.set(true, forKey: "isPro")
                            userDefaults?.synchronize()
                            
                            // Notify the server
                            notifyServer(status: true)
                            return
                        }
                    }
                }
            } catch {
                // Handle verification errors
                print("Verification error: \(error.localizedDescription)")
            }
        }
        
        // If we get here, there's no active subscription
        isSubscriptionActive = false
        expirationDate = nil
        
        // Update UserDefaults to reflect the status
        UserDefaults.standard.set(false, forKey: "isPro")
        
        // Update shared container for extensions
        let userDefaults = UserDefaults(suiteName: "group.com.neocore.tech.TryItOn")
        userDefaults?.set(false, forKey: "isPro")
        userDefaults?.synchronize()
        
        // Notify the server about the status change
        notifyServer(status: false)
    }
    
    // Listen for transaction updates from StoreKit
    private func listenForTransactionUpdates() -> Task<Void, Error> {
        return Task.detached {
            // Watch for transaction updates from the App Store
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    // Update UI on the main thread
                    await self.updateSubscriptionStatus()
                    
                    // Finish the transaction
                    await transaction.finish()
                } catch {
                    // Handle verification error
                    print("Transaction update error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Verify the transaction with Apple
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        // Check if the transaction passes Apple's verification
        switch result {
        case .unverified:
            // Transaction failed verification with Apple
            throw StoreError.failedVerification
        case .verified(let safe):
            // Transaction is verified
            return safe
        }
    }
    
    // Notify the server about subscription status changes
    private func notifyServer(status: Bool) {
        // Skip if there's no username
        guard let username = UserDefaults.standard.string(forKey: "username") else {
            return
        }
        
        // Create the request
        let url = URL(string: "\(APIConfig.baseURL)/users/subscription/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.allHTTPHeaderFields = APIConfig.authHeader(username: username)
        
        // Create and encode the request body
        struct SubscriptionUpdate: Codable {
            let is_pro: Bool
            let expiration_date: String?
        }
        
        // Format the expiration date if available
        let dateFormatter = ISO8601DateFormatter()
        let expirationString = expirationDate.map { dateFormatter.string(from: $0) }
        
        let update = SubscriptionUpdate(
            is_pro: status,
            expiration_date: expirationString
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(update)
            
            // Send the request
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error notifying server about subscription: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Server notification response: \(httpResponse.statusCode)")
                }
            }.resume()
        } catch {
            print("Error encoding subscription update: \(error.localizedDescription)")
        }
    }
}
