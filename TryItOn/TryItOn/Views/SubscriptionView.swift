import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var subscriptionManager = SubscriptionManager()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Text("TryItOn Pro")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Unlimited try-ons, priority processing, and more")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                // Features list
                VStack(alignment: .leading, spacing: 15) {
                    FeatureRow(icon: "infinity", title: "Unlimited Try-Ons", description: "No limits on how many items you can try")
                    FeatureRow(icon: "star.fill", title: "Premium Templates", description: "Access to all template categories")
                    FeatureRow(icon: "bolt.fill", title: "Priority Processing", description: "Faster try-on generation")
                    FeatureRow(icon: "person.fill.badge.plus", title: "Dedicated Support", description: "Direct customer service access")
                }
                .padding(.vertical)
                .padding(.horizontal, 30)
                
                // Subscription offers
                if subscriptionManager.isLoading {
                    ProgressView()
                        .padding()
                } else {
                    ForEach(subscriptionManager.products) { product in
                        SubscriptionCard(
                            product: product,
                            isSubscribed: subscriptionManager.isSubscriptionActive,
                            purchase: {
                                if !subscriptionManager.isSubscriptionActive {
                                    Task {
                                        try? await subscriptionManager.purchase(product)
                                        authManager.isPro = subscriptionManager.isSubscriptionActive
                                    }
                                }
                            }
                        )
                    }
                    
                    // If no products are available
                    if subscriptionManager.products.isEmpty && !subscriptionManager.isLoading {
                        Text("No subscription products available")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                
                // Restore purchases button
                Button(action: {
                    Task {
                        await subscriptionManager.restorePurchases()
                        authManager.isPro = subscriptionManager.isSubscriptionActive
                    }
                }) {
                    Text("Restore Purchases")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .padding(.top)
                
                // Terms and conditions
                Text("Subscription renews automatically. Cancel anytime through App Store settings. Payment will be charged to your Apple ID account at confirmation of purchase.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
                    .padding(.bottom)
            }
            .padding()
        }
        .navigationTitle("Upgrade to Pro")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .alert(item: Binding<StoreAlert?>(
            get: {
                if let error = subscriptionManager.error {
                    return StoreAlert(message: error)
                }
                return nil
            },
            set: { _ in subscriptionManager.error = nil }
        )) { alert in
            Alert(
                title: Text("Error"),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            Task {
                await subscriptionManager.loadProducts()
            }
        }
    }
}

// Helper components
struct FeatureRow: View {
    var icon: String
    var title: String
    var description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SubscriptionCard: View {
    var product: Product
    var isSubscribed: Bool
    var purchase: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            // Price and period
            HStack {
                VStack(alignment: .leading) {
                    Text(product.displayName)
                        .font(.headline)
                    
                    if let subscription = product.subscription {
                        Text("\(product.displayPrice) per \(subscription.subscriptionPeriod.displayUnit)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let offer = subscription.introductoryOffer {
                            Text("\(offer.period.value) \(offer.period.displayUnit) free trial")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Subscribe button
            Button(action: purchase) {
                Text(isSubscribed ? "Subscribed" : "Subscribe")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isSubscribed ? Color.gray : Color.blue)
                    .cornerRadius(10)
            }
            .disabled(isSubscribed)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

// Helper struct for alerts
struct StoreAlert: Identifiable {
    var id = UUID()
    var message: String
}

// Helper extension to format subscription periods
extension Product.SubscriptionPeriod {
    var displayUnit: String {
        switch self.unit {
        case .day: return self.value == 1 ? "day" : "days"
        case .week: return self.value == 1 ? "week" : "weeks"
        case .month: return self.value == 1 ? "month" : "months"
        case .year: return self.value == 1 ? "year" : "years"
        @unknown default: return "period"
        }
    }
}
