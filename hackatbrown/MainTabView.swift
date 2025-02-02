import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    VStack {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                }
                .tag(0)
            
            ScanView()
                .tabItem {
                    VStack {
                        Image(systemName: "qrcode.viewfinder")
                        Text("Scan")
                    }
                }
                .tag(1)
            
            PlanView(selectedTab: $selectedTab)
                .tabItem {
                    VStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Plan")
                    }
                }
                .tag(2)
            
            AlertsView()
                .tabItem {
                    VStack {
                        Image(systemName: "bell.fill")
                        Text("Alerts")
                    }
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    VStack {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                }
                .tag(4)
        }
        .accentColor(Color(red: 0.0, green: 0.48, blue: 0.60))  // Highlight color for selected tab
    }
}
