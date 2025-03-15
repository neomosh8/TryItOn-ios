import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        TabView {
            FittingRoomView()
                .tabItem {
                    Label("Fitting Room", systemImage: "tshirt")
                }
            
            TemplatesView()
                .tabItem {
                    Label("Templates", systemImage: "person.crop.rectangle")
                }
            
            AddItemView()
                .tabItem {
                    Label("Items", systemImage: "square.grid.2x2")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
    }
}
