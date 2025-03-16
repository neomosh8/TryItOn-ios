import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingProUpgradeAlert = false
    
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
                        
                        HStack {
                            Text("Account Type:")
                                .font(.subheadline)
                            
                            Text(authManager.isPro ? "Pro" : "Standard")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(authManager.isPro ? .blue : .gray)
                            
                            if !authManager.isPro {
                                Button(action: {
                                    showingProUpgradeAlert = true
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
                            InfoRow(title: "Account Type", value: authManager.isPro ? "Pro" : "Standard")
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
                        authManager.logout()
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
            .alert(isPresented: $showingProUpgradeAlert) {
                Alert(
                    title: Text("Upgrade to Pro"),
                    message: Text("Pro accounts get access to all template categories and priority support."),
                    primaryButton: .default(Text("Upgrade")) {
                        // Handle upgrade logic here
                        // For demo purposes, we'll just toggle the isPro flag
                        UserDefaults.standard.set(true, forKey: "isPro")
                        authManager.isPro = true
                    },
                    secondaryButton: .cancel()
                )
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
}

// Info row component
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
