import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String? = nil
    @State private var isLoading = false
    
    // Access global authentication state
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Logo at the top right
                HStack {
                    Spacer()
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .padding(.trailing, 10)
                }
                
                // Log in title
                HStack {
                    Text("Log in")
                        .font(.custom("RedditSans-Bold", size: 32))
                        .foregroundColor(Color(red: 0, green: 0.48, blue: 0.60))
                    Spacer()
                }
                
                // Email Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email address")
                        .font(.custom("RedditSans-Regular", size: 14))
                        .foregroundColor(Color(red: 0.251, green: 0.251, blue: 0.251))
                    
                    TextField("example@gmail.com", text: $email)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .foregroundColor(.black)
                }
                
                // Password Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.custom("RedditSans-Regular", size: 14))
                        .foregroundColor(Color(red: 0.251, green: 0.251, blue: 0.251))
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Forgot password link
                HStack {
                    Spacer()
                    Button(action: {
                        // Forgot password logic goes here
                    }) {
                        Text("Forgot password?")
                            .font(.custom("RedditSans-Regular", size: 14))
                            .foregroundColor(Color(red: 0.0, green: 0.48, blue: 0.60))
                    }
                }
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // Log in button
                Button(action: login) {
                    Text("Log in")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0, green: 0.48, blue: 0.60))
                        .cornerRadius(8)
                }
                .disabled(isLoading)
                
                Spacer()
                
                // Sign-up link
                HStack {
                    Text("Don’t have an account? ")
                        .foregroundColor(Color(red: 0.251, green: 0.251, blue: 0.251))
                        .font(.footnote)
                    
                    NavigationLink(destination: SignUpView()) {
                        Text("Sign up")
                            .foregroundColor(Color(red: 0.0, green: 0.48, blue: 0.60))
                            .font(.footnote)
                    }
                }
                .padding(.bottom, 20)
            }
            .padding()
        }
    }
    
    private func login() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }
        
        isLoading = true
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Login failed: \(error.localizedDescription)"
            } else if let result = result {
                let uid = result.user.uid
                // Save uid to UserDefaults for use by other parts of the app.
                UserDefaults.standard.set(uid, forKey: "uid")
                print("Login successful. UID: \(uid)")
                authViewModel.isLoggedIn = true
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView().environmentObject(AuthViewModel())
    }
}
