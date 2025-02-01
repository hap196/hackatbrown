import SwiftUI
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false  // Tracks login state

    init() {
        checkAuthState()
    }

    /// Check the current authentication state
    func checkAuthState() {
        if Auth.auth().currentUser != nil {
            // User is already logged in
            isLoggedIn = true
        } else {
            // User is not logged in
            isLoggedIn = false
        }
    }

    /// Log out the user
    func signOut() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
