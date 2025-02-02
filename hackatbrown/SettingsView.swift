import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel  // Access the auth state

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var isEditing = false

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button(action: { isEditing.toggle() }) {
                    Text(isEditing ? "Done" : "Edit")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)

            // Profile Picture Section
            VStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)

                Text("Change profile picture")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 12) {
                // First Name
                VStack(alignment: .leading) {
                    Text("First Name")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    TextField("Enter first name", text: $firstName)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .disabled(!isEditing)
                }

                // Last Name
                VStack(alignment: .leading) {
                    Text("Last Name")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    TextField("Enter last name", text: $lastName)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .disabled(!isEditing)
                }

                // Email (non-editable)
                VStack(alignment: .leading) {
                    Text("Email address")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .disabled(true)
                }
            }
            .padding()

            if isEditing {
                Button(action: updateUser) {
                    Text("Save Changes")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            }

            Spacer()

            Button(action: { authViewModel.signOut() }) {
                Text("Log Out")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
            }
            .padding()
        }
        .onAppear {
            loadUserInfo()
        }
        .padding()
    }

    private func loadUserInfo() {
        email = authViewModel.currentUserEmail
        // Optionally, fetch first and last name from backend
    }

    private func updateUser() {
        guard !firstName.isEmpty, !lastName.isEmpty else {
            print("First and last names cannot be empty.")
            return
        }

        let userUpdateData: [String: Any] = [
            "uid": authViewModel.currentUserUID,
            "email": email,
            "name": "\(firstName) \(lastName)"
        ]

        guard let url = URL(string: "http://localhost:3000/users") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        guard let httpBody = try? JSONSerialization.data(withJSONObject: userUpdateData) else {
            print("Failed to encode user data")
            return
        }

        request.httpBody = httpBody

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error updating user: \(error)")
                return
            }
            print("User updated successfully.")
        }.resume()
    }
}

#Preview {
    SettingsView().environmentObject(AuthViewModel())
}
