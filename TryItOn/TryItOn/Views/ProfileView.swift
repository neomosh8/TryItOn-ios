import SwiftUI
import StoreKit

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var showingSubscriptionView = false
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile header with photo
                    VStack {
                        if let profileImage = authManager.profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                                .shadow(radius: 5)
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .foregroundColor(.blue)
                        }
                        
                        Text(authManager.username)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if !authManager.email.isEmpty {
                            Text(authManager.email)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        // Subscription status
                        HStack(spacing: 8) {
                            Text("Account Type:")
                                .font(.subheadline)
                            
                            if subscriptionManager.isSubscriptionActive {
                                Label("Pro", systemImage: "checkmark.seal.fill")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            } else {
                                Text("Standard")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                
                                Button(action: {
                                    showingSubscriptionView = true
                                }) {
                                    Text("Upgrade")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.top, 5)
                        
                        // Show subscription expiration if applicable
                        if subscriptionManager.isSubscriptionActive, let expirationDate = subscriptionManager.expirationDate {
                            Text("Renews \(expirationDate, formatter: dateFormatter)")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 2)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    
                    // Account info section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("ACCOUNT INFORMATION")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                            .padding(.leading)
                            .padding(.bottom, 5)
                        
                        VStack(spacing: 0) {
                            InfoRow(title: "Username", value: authManager.username)
                            Divider().padding(.leading)
                            InfoRow(title: "Sign-in Method", value: authProvider)
                            Divider().padding(.leading)
                            InfoRow(title: "Account Type", value: subscriptionManager.isSubscriptionActive ? "Pro" : "Standard")
                            
                            if subscriptionManager.isSubscriptionActive {
                                Divider().padding(.leading)
                                Button(action: {
                                    // Open subscription management in Settings
                                    if let url = URL(string: "App-Prefs:root=STORE") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack {
                                        Text("Manage Subscription")
                                            .foregroundColor(.blue)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                }
                            } else {
                                Divider().padding(.leading)
                                Button(action: {
                                    showingSubscriptionView = true
                                }) {
                                    HStack {
                                        Text("Upgrade to Pro")
                                            .foregroundColor(.blue)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    
                    // Privacy section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("PRIVACY")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                            .padding(.leading)
                            .padding(.bottom, 5)
                        
                        VStack(spacing: 0) {
                            NavigationLink(destination: Text("Privacy Settings")) {
                                HStack {
                                    Image(systemName: "lock.shield")
                                        .foregroundColor(.blue)
                                        .frame(width: 25)
                                    Text("Privacy Settings")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                            }
                            Divider().padding(.leading)
                            NavigationLink(destination: Text("Terms and Conditions")) {
                                HStack {
                                    Image(systemName: "doc.text")
                                        .foregroundColor(.blue)
                                        .frame(width: 25)
                                    Text("Terms and Conditions")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                            }
                            
                            if subscriptionManager.isSubscriptionActive {
                                Divider().padding(.leading)
                                Button(action: {
                                    Task {
                                        await subscriptionManager.restorePurchases()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                            .foregroundColor(.blue)
                                            .frame(width: 25)
                                        Text("Restore Purchases")
                                        Spacer()
                                        if subscriptionManager.isLoading {
                                            ProgressView()
                                                .scaleEffect(0.7)
                                        }
                                    }
                                    .padding()
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    
                    // Sign out button
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.right.square")
                            Text("Sign Out")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // App version at the bottom
                    Text("TryItOn v1.0.0")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
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

// Keep the existing InfoRow struct
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding()
    }
}
