import SwiftUI
struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var username: String = ""
    @State private var isPro: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tshirt.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("TryItOn")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Toggle("Pro Account", isOn: $isPro)
                .padding(.horizontal)
            
            Button(action: {
                authManager.login(username: username, isPro: isPro)
            }) {
                Text("Sign In / Register")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(username.isEmpty)
        }
        .padding()
        .onAppear {
            authManager.checkSavedLogin()
        }
    }
}

// Main Tab View
struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        TabView {
            ResultsListView()
                .tabItem {
                    Label("Results", systemImage: "photo.on.rectangle")
                }
            
            TemplatesView()
                .tabItem {
                    Label("Templates", systemImage: "person.crop.rectangle")
                }
            
            TryOnView()
                .tabItem {
                    Label("Try On", systemImage: "tshirt")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
    }
}
