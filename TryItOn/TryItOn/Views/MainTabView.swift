// Main Tab View
import SwiftUI

// MainTabView (update the existing struct in LoginView.swift)
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
            
            FittingRoomView()
                .tabItem {
                    Label("Fitting Room", systemImage: "rectangle.and.text.magnifyingglass")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
            AddItemView()
                            .tabItem {
                                Label("Add Item", systemImage: "plus.circle")
                            }
        }
    }
}
