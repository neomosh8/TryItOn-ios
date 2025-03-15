import SwiftUI


// Profile View
struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account")) {
                    HStack {
                        Text("Username")
                        Spacer()
                        Text(authManager.username)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Account Type")
                        Spacer()
                        Text(authManager.isPro ? "Pro" : "Standard")
                            .foregroundColor(.gray)
                    }
                }
                
                Section {
                    Button(action: {
                        authManager.logout()
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}
