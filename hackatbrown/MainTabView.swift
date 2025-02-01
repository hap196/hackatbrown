import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    VStack {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                }
            
            ScanView()
                .tabItem {
                    VStack {
                        Image(systemName: "qrcode.viewfinder")
                        Text("Scan")
                    }
                }
            
            PlanView()
                .tabItem {
                    VStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Plan")
                    }
                }
            
            AlertsView()
                .tabItem {
                    VStack {
                        Image(systemName: "bell.fill")
                        Text("Alerts")
                    }
                }
            
            SettingsView()
                .tabItem {
                    VStack {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                }
        }
        .accentColor(Color(red: 0.0, green: 0.48, blue: 0.60))  // Highlight color for selected tab
    }
}
