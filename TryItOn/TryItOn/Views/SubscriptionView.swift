import SwiftUI
import StoreKit
struct StoreAlert: Identifiable {
    var id = UUID()
    var message: String
}

// Add this extension at the bottom of the file
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
struct SubscriptionView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var subscriptionManager = SubscriptionManager()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header with enhanced styling
                    VStack(spacing: 16) {
                        // Crown icon
                        Image(systemName: "crown.fill")
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.accentColor)
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .shadow(color: AppTheme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                        
                        Text("TryItOn Pro")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(hex: "333333"))
                        
                        Text("Elevate your style experience")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "666666"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Features list with enhanced styling
                    VStack(alignment: .leading, spacing: 20) {
                        FeatureRow(icon: "infinity", title: "Unlimited Try-Ons",
                                   description: "No limits on how many items you can try",
                                   color: AppTheme.accentColor)
                        
                        FeatureRow(icon: "star.fill", title: "Premium Templates",
                                   description: "Access to all template categories",
                                   color: AppTheme.secondaryColor)
                        
                        FeatureRow(icon: "bolt.fill", title: "Priority Processing",
                                   description: "Faster try-on generation",
                                   color: AppTheme.tertiaryColor)
                        
                        FeatureRow(icon: "person.fill.badge.plus", title: "Dedicated Support",
                                   description: "Direct customer service access",
                                   color: AppTheme.accentColor)
                    }
                    .padding(.vertical)
                    .padding(.horizontal, 24)
                    
                    // Subscription offers with enhanced styling
                    if subscriptionManager.isLoading {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.accentColor))
                            
                            Text("Loading subscription options...")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "666666"))
                                .padding(.top, 12)
                        }
                        .padding(.vertical, 40)
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
                                .foregroundColor(Color(hex: "666666"))
                                .padding()
                        }
                    }
                    
                    // Restore purchases button with enhanced styling
                    Button(action: {
                        Task {
                            await subscriptionManager.restorePurchases()
                            authManager.isPro = subscriptionManager.isSubscriptionActive
                        }
                    }) {
                        Text("Restore Purchases")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.accentColor)
                            .padding(.vertical, 8)
                    }
                    .padding(.top, 4)
                    
                    // Terms and conditions with enhanced styling
                    Text("Subscription renews automatically. Cancel anytime through App Store settings. Payment will be charged to your Apple ID account at confirmation of purchase.")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "999999"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                }
                .padding()
            }
            .navigationTitle("Upgrade to Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accentColor)
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
}
// Updated FeatureRow with customizable color
struct FeatureRow: View {
    var icon: String
    var title: String
    var description: String
    var color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "333333"))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "666666"))
            }
        }
    }
}

// Updated SubscriptionCard with feminine styling
struct SubscriptionCard: View {
    var product: Product
    var isSubscribed: Bool
    var purchase: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Price and period
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "333333"))
                    
                    if let subscription = product.subscription {
                        Text("\(product.displayPrice) per \(subscription.subscriptionPeriod.displayUnit)")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "666666"))
                        
                        if let offer = subscription.introductoryOffer {
                            HStack {
                                Text("\(offer.period.value) \(offer.period.displayUnit) free trial")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(AppTheme.secondaryColor)
                                    .cornerRadius(12)
                            }
                            .padding(.top, 2)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Subscribe button with enhanced styling
            Button(action: purchase) {
                Text(isSubscribed ? "Current Plan" : "Subscribe")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(isSubscribed ? Color.gray : AppTheme.accentColor)
                    .cornerRadius(AppTheme.buttonCornerRadius)
                    .shadow(color: isSubscribed ? Color.clear : AppTheme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(isSubscribed)
        }
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: AppTheme.shadowColor, radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}
