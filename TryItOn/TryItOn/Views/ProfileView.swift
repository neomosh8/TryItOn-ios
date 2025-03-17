import SwiftUI
import StoreKit

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var showingSubscriptionView = false
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile header with photo - improved sizing and layout
                        VStack {
                            if let profileImage = authManager.profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(AppTheme.accentColor, lineWidth: 3))
                                    .shadow(color: AppTheme.shadowColor, radius: 8, x: 0, y: 4)
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.cardBackground)
                                        .frame(width: 100, height: 100)
                                        .shadow(color: AppTheme.shadowColor, radius: 8, x: 0, y: 4)
                                    
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 70, height: 70)
                                        .foregroundColor(AppTheme.accentColor)
                                }
                            }
                            
                            Text(authManager.username)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Color(hex: "333333"))
                                .padding(.top, 8)
                            
                            if !authManager.email.isEmpty {
                                Text(authManager.email)
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "666666"))
                            }
                            
                            // Subscription status with enhanced styling
                            HStack(spacing: 8) {
                                if subscriptionManager.isSubscriptionActive {
                                    Label("Pro Account", systemImage: "star.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(AppTheme.secondaryColor)
                                        .cornerRadius(AppTheme.cornerRadius)
                                } else {
                                    Button(action: {
                                        showingSubscriptionView = true
                                    }) {
                                        Label("Upgrade to Pro", systemImage: "star")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(AppTheme.accentColor)
                                            .cornerRadius(AppTheme.cornerRadius)
                                            .shadow(color: AppTheme.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                                    }
                                }
                            }
                            .padding(.top, 12)
                            
                            // Show subscription expiration if applicable
                            if subscriptionManager.isSubscriptionActive, let expirationDate = subscriptionManager.expirationDate {
                                Text("Renews \(expirationDate, formatter: dateFormatter)")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "666666"))
                                    .padding(.top, 4)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .fill(Color.white)
                                .shadow(color: AppTheme.shadowColor, radius: 6, x: 0, y: 3)
                        )
                        .padding(.horizontal)
                        
                        // Account info section with fixed width for rows
                        VStack(alignment: .leading, spacing: 0) {
                            Text("ACCOUNT INFORMATION")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.accentColor)
                                .padding(.leading)
                                .padding(.bottom, 5)
                            
                            VStack(spacing: 0) {
                                InfoRow(title: "Username", value: authManager.username, iconName: "person.fill")
                                Divider().padding(.horizontal)
                                InfoRow(title: "Sign-in Method", value: authProvider, iconName: "lock.fill")
                                Divider().padding(.horizontal)
                                InfoRow(title: "Account Type", value: subscriptionManager.isSubscriptionActive ? "Pro" : "Standard",
                                       iconName: subscriptionManager.isSubscriptionActive ? "star.fill" : "star")
                                
                                if subscriptionManager.isSubscriptionActive {
                                    Divider().padding(.horizontal)
                                    Button(action: {
                                        // Open subscription management in Settings
                                        if let url = URL(string: "App-Prefs:root=STORE") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "creditcard.fill")
                                                .foregroundColor(AppTheme.secondaryColor)
                                                .frame(width: 24)
                                            
                                            Text("Manage Subscription")
                                                .foregroundColor(Color(hex: "333333"))
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(Color(hex: "999999"))
                                                .font(.system(size: 14))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 16)
                                    }
                                } else {
                                    Divider().padding(.horizontal)
                                    Button(action: {
                                        showingSubscriptionView = true
                                    }) {
                                        HStack {
                                            Image(systemName: "crown.fill")
                                                .foregroundColor(AppTheme.accentColor)
                                                .frame(width: 24)
                                            
                                            Text("Upgrade to Pro")
                                                .foregroundColor(Color(hex: "333333"))
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(Color(hex: "999999"))
                                                .font(.system(size: 14))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 16)
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(AppTheme.cornerRadius)
                            .shadow(color: AppTheme.shadowColor, radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                        
                        // Privacy section with fixed width for rows
                        VStack(alignment: .leading, spacing: 0) {
                            Text("PRIVACY & SUPPORT")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.accentColor)
                                .padding(.leading)
                                .padding(.bottom, 5)
                            
                            VStack(spacing: 0) {
                                // Privacy Settings
                                NavigationLink(destination: PrivacySettingsView()) {
                                    HStack {
                                        Image(systemName: "lock.shield.fill")
                                            .foregroundColor(AppTheme.secondaryColor)
                                            .frame(width: 24)
                                        
                                        Text("Privacy Settings")
                                            .foregroundColor(Color(hex: "333333"))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(Color(hex: "999999"))
                                            .font(.system(size: 14))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                }
                                
                                Divider().padding(.horizontal)
                                
                                // Privacy Policy
                                NavigationLink(destination: TermsAndPrivacyView(documentType: .privacy)) {
                                    HStack {
                                        Image(systemName: "hand.raised.fill")
                                            .foregroundColor(AppTheme.secondaryColor)
                                            .frame(width: 24)
                                        
                                        Text("Privacy Policy")
                                            .foregroundColor(Color(hex: "333333"))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(Color(hex: "999999"))
                                            .font(.system(size: 14))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                }
                                
                                Divider().padding(.horizontal)
                                
                                // Terms of Service
                                NavigationLink(destination: TermsAndPrivacyView(documentType: .terms)) {
                                    HStack {
                                        Image(systemName: "doc.text.fill")
                                            .foregroundColor(AppTheme.secondaryColor)
                                            .frame(width: 24)
                                        
                                        Text("Terms and Conditions")
                                            .foregroundColor(Color(hex: "333333"))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(Color(hex: "999999"))
                                            .font(.system(size: 14))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                }
                                
                                if subscriptionManager.isSubscriptionActive {
                                    Divider().padding(.horizontal)
                                    Button(action: {
                                        Task {
                                            await subscriptionManager.restorePurchases()
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "arrow.clockwise")
                                                .foregroundColor(AppTheme.secondaryColor)
                                                .frame(width: 24)
                                            
                                            Text("Restore Purchases")
                                                .foregroundColor(Color(hex: "333333"))
                                            Spacer()
                                            if subscriptionManager.isLoading {
                                                ProgressView()
                                                    .scaleEffect(0.7)
                                                    .tint(AppTheme.accentColor)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 16)
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(AppTheme.cornerRadius)
                            .shadow(color: AppTheme.shadowColor, radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                        
                        // Sign out button with updated styling
                        Button(action: {
                            showingLogoutAlert = true
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: "arrow.right.square")
                                    .foregroundColor(.white)
                                Text("Sign Out")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius)
                                    .fill(Color(hex: "ff6b8e"))
                            )
                            .shadow(color: Color(hex: "ff6b8e").opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // App version at the bottom with updated styling
                        Text("TryItOn v1.0.0")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "999999"))
                            .padding(.top, 20)
                            .padding(.bottom, 30)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingSubscriptionView) {
                NavigationView {
                    SubscriptionView()
                        .environmentObject(subscriptionManager)
                }
            }
            .alert(isPresented: $showingLogoutAlert) {
                Alert(
                    title: Text("Sign Out"),
                    message: Text("Are you sure you want to sign out?"),
                    primaryButton: .destructive(Text("Sign Out")) {
                        authManager.logout()
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear {
                // Update subscription status when view appears
                Task {
                    await subscriptionManager.updateSubscriptionStatus()
                    // Keep AuthManager in sync with subscription status
                    DispatchQueue.main.async {
                        authManager.isPro = subscriptionManager.isSubscriptionActive
                    }
                }
            }
        }
    }
    
    // Helper computed property to display the auth provider nicely
    private var authProvider: String {
        switch authManager.authProvider {
        case .custom:
            return "Username"
        case .google:
            return "Google"
        case .apple:
            return "Apple"
        }
    }
    
    // Date formatter for subscription expiration
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

// Updated InfoRow with better padding and layout
struct InfoRow: View {
    let title: String
    let value: String
    let iconName: String
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(AppTheme.secondaryColor)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(Color(hex: "666666"))
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "333333"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}
