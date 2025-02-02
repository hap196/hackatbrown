import SwiftUI
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUserEmail: String = ""
    @Published var currentUserUID: String = ""

    init() {
        checkAuthState()
    }

    /// Check the current authentication state and update user info
    func checkAuthState() {
        if let user = Auth.auth().currentUser {
            isLoggedIn = true
            currentUserEmail = user.email ?? ""
            currentUserUID = user.uid
        } else {
            isLoggedIn = false
            currentUserEmail = ""
            currentUserUID = ""
        }
    }

    /// Log out the user
    func signOut() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
            currentUserEmail = ""
            currentUserUID = ""
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
