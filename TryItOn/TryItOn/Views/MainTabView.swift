import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        TabView {
            FittingRoomView()
                .tabItem {
                    Label("My Closet", systemImage: "tshirt.fill")
                }
            
            TemplatesView()
                .tabItem {
                    Label("Models", systemImage: "person.crop.rectangle.fill")
                }
            
            AddItemView()
                .tabItem {
                    Label("Add Items", systemImage: "plus.circle.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
        }
        .accentColor(AppTheme.accentColor) // Set the accent color for the tab bar
        .onAppear {
            // Set the tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.backgroundColor = UIColor(Color.white.opacity(0.95))
            appearance.shadowColor = UIColor(Color(hex: "ffcfe1").opacity(0.2))
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}
