import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var isEditing = false
    
    // Allergy management
    @State private var allergies: [String] = []
    @State private var newAllergy: String = ""
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 10) {
                // Title and Edit Button
                HStack {
                    Text("Settings")
                        .font(.custom("RedditSans-Bold", size: 28))
                        .foregroundColor(Color(red: 0, green: 0.48, blue: 0.60))
                    
                    Spacer()
                    
                    Button(action: {
                        if isEditing {
                            updateUser()
                        }
                        isEditing.toggle()
                    }) {
                        Text(isEditing ? "Done" : "Edit")
                            .font(.custom("RedditSans-Regular", size: 18))
                            .foregroundColor(Color(red: 0, green: 0.48, blue: 0.60))
                    }
                }
                .padding(.top, 10)
                .padding(.horizontal)
                
                Form {
                    // User Information Section
                    Section(header: sectionHeader("User Information")) {
                        userInfoRow(label: "First Name:", text: $firstName)
                        userInfoRow(label: "Last Name:", text: $lastName)
                        nonEditableInfoRow(label: "Email:", value: email)
                    }
                    
                    // Allergies Section
                    Section(header: sectionHeader("Allergies")) {
                        if allergies.isEmpty {
                            Text("No allergies. Press Edit to add allergies.")
                                .font(.custom("RedditSans-Regular", size: 16))
                                .foregroundColor(.gray)
                        } else {
                            ForEach(allergies.indices, id: \.self) { index in
                                HStack {
                                    TextField("Enter allergy", text: Binding(
                                        get: { allergies[index] },
                                        set: { allergies[index] = $0 }
                                    ))
                                    .font(.custom("RedditSans-Regular", size: 16))
                                    .foregroundColor(.black)
                                    
                                    if isEditing {
                                        Button(action: {
                                            removeAllergy(at: index)
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                        }
                        
                        if isEditing {
                            HStack {
                                TextField("Add new allergy", text: $newAllergy)
                                    .font(.custom("RedditSans-Regular", size: 16))
                                Button(action: addAllergy) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(Color(red: 0, green: 0.48, blue: 0.60))
                                }
                            }
                        }
                    }
                }
                
                // Log Out Button
                Button(action: { authViewModel.signOut() }) {
                    Text("Log Out")
                        .font(.custom("RedditSans-Bold", size: 18))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarHidden(true)
            .onAppear {
                loadUserInfo()
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func userInfoRow(label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(.custom("RedditSans-Regular", size: 16))
            Spacer()
            if isEditing {
                TextField("Enter \(label.lowercased())", text: text)
                    .multilineTextAlignment(.trailing)
                    .font(.custom("RedditSans-Regular", size: 16))
            } else {
                Text(text.wrappedValue)
                    .font(.custom("RedditSans-Regular", size: 16))
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func nonEditableInfoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.custom("RedditSans-Regular", size: 16))
            Spacer()
            Text(value)
                .font(.custom("RedditSans-Regular", size: 16))
                .foregroundColor(.gray)
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.custom("RedditSans-Bold", size: 18))
            .foregroundColor(Color(red: 0, green: 0.48, blue: 0.60))
    }
    
    // MARK: - Logic Methods
    
    private func loadUserInfo() {
        email = authViewModel.currentUserEmail
        // Optionally fetch first and last name and allergies from the backend if needed.
    }
    
    private func addAllergy() {
        guard !newAllergy.isEmpty else { return }
        allergies.append(newAllergy)
        newAllergy = ""
        // Optionally save updated allergies to the backend.
    }
    
    private func removeAllergy(at index: Int) {
        allergies.remove(at: index)
        // Optionally save updated allergies to the backend.
    }
    
    private func updateUser() {
        guard !firstName.isEmpty, !lastName.isEmpty else {
            print("First and last names cannot be empty.")
            return
        }

        let userUpdateData: [String: Any] = [
            "uid": authViewModel.currentUserUID,
            "email": email,
            "name": "\(firstName) \(lastName)",
            "allergies": allergies
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
