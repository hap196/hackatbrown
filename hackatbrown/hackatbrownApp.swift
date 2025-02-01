import SwiftUI
import Firebase

@main
struct hackatbrownApp: App {
    
    init() {
        // initialize Firebase when the app starts
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            // show loginview
            LandingView()
        }
    }
}
