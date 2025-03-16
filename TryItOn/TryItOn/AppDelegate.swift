import UIKit
import StoreKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    let authManager = AuthManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Run shared container diagnostics
        SharedContainer.shared.diagnoseAndFix()
        
        // Initialize StoreKit transaction listener
        Task {
            await updateSubscriptionStatus()
            
            // Listen for transactions
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)
                    
                    // Update subscription status
                    await updateSubscriptionStatus()
                    
                    // Finish the transaction
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
        
        return true
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    func updateSubscriptionStatus() async {
        for tier in SubscriptionTier.allCases {
            do {
                // Fix: Properly unwrap the optional result
                if let result = try await Transaction.latest(for: tier.rawValue) {
                    if let transaction = try? checkVerified(result) {
                        let isActive = transaction.revocationDate == nil &&
                                      !transaction.isUpgraded &&
                                      (transaction.expirationDate == nil || transaction.expirationDate! > Date())
                        
                        if isActive {
                            // Update the AuthManager on the main thread
                            DispatchQueue.main.async {
                                self.authManager.updateSubscriptionStatus(isActive: true)
                            }
                            return
                        }
                    }
                }
            } catch {
                print("Failed to check subscription status: \(error)")
            }
        }
        
        // No active subscription found
        DispatchQueue.main.async {
            self.authManager.updateSubscriptionStatus(isActive: false)
        }
    }
}
