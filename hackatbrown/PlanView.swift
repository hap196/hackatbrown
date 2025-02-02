import SwiftUI

struct PlanView: View {
    @Binding var selectedTab: Int  // Binding passed from the parent TabView
    
    @State private var pillName: String = ""
    @State private var pillAmount: String = ""
    @State private var duration: String = ""
    @State private var howOften: String = "Daily"
    @State private var selectedFoodOption: String? = nil
    @State private var specificTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var notificationBefore: String = "10 minutes before"
    @State private var additionalDetails: String = ""
    @State private var showCustomRecurrence = false
    @State private var showErrorMessage = false

    let notificationOptions = ["No Notification", "5 minutes before", "10 minutes before", "15 minutes before", "30 minutes before", "1 hour before", "2 hours before"]
    let frequencyOptions = ["Daily", "Every 2 days", "Weekly", "Monthly", "Custom"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text("Add Plan")
                    .font(.custom("RedditSans-Bold", size: 28))
                    .foregroundColor(Color(red: 0, green: 0.48, blue: 0.60))

                // Pills Name Section
                VStack(alignment: .leading) {
                    Text("Pills name *")
                        .font(.custom("RedditSans-Regular", size: 16))
                    HStack {
                        Image(systemName: "pills.fill")
                            .foregroundColor(.gray)
                        TextField("Enter pill name", text: $pillName)
                            .padding(.leading, 8)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }

                // Amount & Duration Section
                VStack(alignment: .leading) {
                    Text("Amount & Duration *")
                        .font(.custom("RedditSans-Regular", size: 16))
                    HStack(spacing: 10) {
                        // Pill amount input with reduced width
                        HStack {
                            Image(systemName: "pills")
                                .foregroundColor(.gray)
                            TextField("Amount", text: $pillAmount)
                                .keyboardType(.numberPad)
                        }
                        .padding()
                        .frame(maxWidth: 140)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)

                        // Duration input with more space
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.gray)
                            TextField("Duration (days)", text: $duration)
                                .keyboardType(.numberPad)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }

                // How Often Section
                VStack(alignment: .leading) {
                    Text("How often *")
                        .font(.custom("RedditSans-Regular", size: 16))
                    Menu {
                        ForEach(frequencyOptions, id: \.self) { option in
                            Button(option) {
                                howOften = option
                                if option == "Custom" {
                                    showCustomRecurrence = true
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(howOften)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .sheet(isPresented: $showCustomRecurrence) {
                    CustomRecurrenceView(showSheet: $showCustomRecurrence)
                }

                // Specific Time Section
                VStack(alignment: .leading) {
                    Text("Specific time & Notification")
                        .font(.custom("RedditSans-Regular", size: 16))
                    
                    // Time input
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.gray)
                        DatePicker("", selection: $specificTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .background(Color.clear)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Notification dropdown
                    Menu {
                        ForEach(notificationOptions, id: \.self) { option in
                            Button(option) {
                                notificationBefore = option
                            }
                        }
                    } label: {
                        HStack {
                            Text(notificationBefore)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // Food & Pills Section
                VStack(alignment: .leading) {
                    Text("Food & Pills")
                        .font(.custom("RedditSans-Regular", size: 16))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(["Before Breakfast", "After Breakfast", "Before Lunch", "After Lunch", "Before Dinner", "After Dinner"], id: \.self) { option in
                                Button(action: {
                                    selectedFoodOption = selectedFoodOption == option ? nil : option
                                }) {
                                    Text(option)
                                        .padding()
                                        .foregroundColor(.black)
                                        .background(selectedFoodOption == option ? Color.gray.opacity(0.4) : Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                
                // Additional Details Section
                VStack(alignment: .leading) {
                    Text("Additional details")
                        .font(.custom("RedditSans-Regular", size: 16))
                    TextEditor(text: $additionalDetails)
                        .padding(10)
                        .frame(minHeight: 150)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .foregroundColor(.black)
                }
                
                if showErrorMessage {
                    Text("Please fill in all required fields.")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // Done Button (Full Width)
                Button(action: validateAndSubmit) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0, green: 0.48, blue: 0.60))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .navigationDestination(isPresented: $navigateToHome) {
            HomeView()
        }
    }
    
    @State private var navigateToHome: Bool = false
    
    private func validateAndSubmit() {
        guard !pillName.isEmpty, !pillAmount.isEmpty, !duration.isEmpty else {
            showErrorMessage = true
            return
        }
        showErrorMessage = false
        print("Plan: \(pillName), \(pillAmount) pills, \(duration) days, \(howOften)")
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"  // e.g., "08:31 AM"
        
        let pillData: [String: Any] = [
            "pillName": pillName,
            "amount": Int(pillAmount) ?? 0,
            "duration": Int(duration) ?? 0,
            "howOften": howOften,
            "specificTime": timeFormatter.string(from: specificTime),
            "foodInstruction": selectedFoodOption ?? "",
            "notificationBefore": notificationBefore,
            "additionalDetails": additionalDetails
        ]
        
        savePillDataToBackend(pillData)
        // Update the tab selection to switch to the Home tab (index 0).
        selectedTab = 0
    }
    
    private func savePillDataToBackend(_ pillData: [String: Any]) {
        guard let uid = UserDefaults.standard.string(forKey: "uid") else {
            print("User uid not available")
            return
        }
//        guard let url = URL(string: "http://localhost:3000/users/\(uid)/pills") else {
//            print("Invalid URL")
//            return
//        }
        guard let url = URL(string: "https://hackatbrown.onrender.com/users/\(uid)/pills") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: pillData, options: []) else {
            print("Error encoding data")
            return
        }
        request.httpBody = httpBody
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error saving pill data: \(error)")
                return
            }
            print("Pill data saved successfully.")
        }.resume()
    }
}

struct CustomRecurrenceView: View {
    @Binding var showSheet: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Custom Recurrence")
                .font(.headline)

            HStack {
                Text("Repeat every")
                TextField("1", text: .constant("1"))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 50)
                Menu {
                    Button("Day") { }
                    Button("Week") { }
                    Button("Month") { }
                } label: {
                    Text("Week")
                }
            }

            Button("Done") {
                showSheet = false
            }
            .padding()
        }
        .padding()
    }
}

#Preview {
    NavigationView {
        // In your preview, we pass a constant binding (e.g., index 2).
        PlanView(selectedTab: .constant(2))
    }
}
