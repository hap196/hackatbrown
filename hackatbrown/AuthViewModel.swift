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
            // Save uid to UserDefaults so that other parts of the app can read it.
            UserDefaults.standard.set(user.uid, forKey: "uid")
        } else {
            isLoggedIn = false
            currentUserEmail = ""
            currentUserUID = ""
            UserDefaults.standard.removeObject(forKey: "uid")
        }
    }
    
    /// Log out the user
    func signOut() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
            currentUserEmail = ""
            currentUserUID = ""
            UserDefaults.standard.removeObject(forKey: "uid")
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
