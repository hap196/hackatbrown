import SwiftUI
import FirebaseAuth
import Foundation

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String? = nil
    @State private var isLoading = false

    var body: some View {
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

            // Sign-up title
            HStack {
                Text("Sign up")
                    .font(.custom("RedditSans-Bold", size: 32))
                    .foregroundColor(Color(red: 0, green: 0.48, blue: 0.60))
                Spacer()  // Left-aligns the title
            }

            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
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

            // Create Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Create a password")
                    .font(.custom("RedditSans-Regular", size: 14))
                    .foregroundColor(Color(red: 0.251, green: 0.251, blue: 0.251))

                SecureField("must be 8 characters", text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }

            // Confirm Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm password")
                    .font(.custom("RedditSans-Regular", size: 14))
                    .foregroundColor(Color(red: 0.251, green: 0.251, blue: 0.251))

                SecureField("repeat password", text: $confirmPassword)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }

            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            // Sign-up button
            Button(action: signUp) {
                Text("Sign up")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0, green: 0.48, blue: 0.60))
                    .cornerRadius(8)
            }
            .disabled(isLoading)

            Spacer()  // Pushes the sign-up link to the bottom

            // Navigation to Login
            HStack {
                Text("Already have an account? ")
                    .foregroundColor(Color(red: 0.251, green: 0.251, blue: 0.251))
                    .font(.footnote)

                NavigationLink(destination: LoginView()) {
                    Text("Log in")
                        .foregroundColor(Color(red: 0.0, green: 0.48, blue: 0.60))
                        .font(.footnote)
                }
            }
        }
        .padding()
    }

    /// Sign-up logic using Firebase and saving to the database
    private func signUp() {
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        isLoading = true

        // Create the user using Firebase Authentication
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            self.isLoading = false

            if let error = error {
                errorMessage = "Sign-up failed: \(error.localizedDescription)"
            } else if let result = result {
                let uid = result.user.uid
                let name = "User Name"  // Replace with actual user input if you collect it
                print("Firebase user created with UID: \(uid)")

                // Save user details to MongoDB via backend
                saveUserToDatabase(uid: uid, email: email, name: name)

                print("Sign-up successful")
            }
        }
    }
}

/// Save user details to the backend API connected to MongoDB
func saveUserToDatabase(uid: String, email: String, name: String) {
    guard let url = URL(string: "http://localhost:3000/users") else {
        print("Invalid backend URL")
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let user = ["uid": uid, "email": email, "name": name]
    guard let httpBody = try? JSONSerialization.data(withJSONObject: user, options: []) else {
        print("Failed to serialize user data")
        return
    }
    request.httpBody = httpBody

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error saving user to database: \(error)")
            return
        }
        print("User saved successfully to MongoDB")
    }.resume()
}
