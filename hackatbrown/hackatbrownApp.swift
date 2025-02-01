import SwiftUI
import Firebase

@main
struct hackatbrownApp: App {
    // Initialize Firebase
    init() {
        FirebaseApp.configure()
    }

    // Global authentication state
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            if authViewModel.isLoggedIn {
                MainTabView()  // Show main tab navigation if logged in
                    .environmentObject(authViewModel)
            } else {
                LandingView()  // Show login or sign-up if not logged in
                    .environmentObject(authViewModel)
            }
        }
    }
}
