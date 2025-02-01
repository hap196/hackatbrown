import SwiftUI
import FirebaseAuth

struct PlanView: View {
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
                Text("Add Plan")
                    .font(.custom("RedditSans-Bold", size: 32))
                    .foregroundColor(.black)

                // Pills Name Section
                VStack(alignment: .leading) {
                    Text("Pills name *")
                        .font(.custom("RedditSans-Regular", size: 16))
                    TextField("Enter pill name", text: $pillName)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }

                // Amount & Duration Section
                VStack(alignment: .leading) {
                    Text("Amount & Duration *")
                        .font(.custom("RedditSans-Regular", size: 16))
                    HStack {
                        TextField("Amount", text: $pillAmount)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)

                        TextField("Duration (days)", text: $duration)
                            .keyboardType(.numberPad)
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
                    HStack {
                        DatePicker("Time", selection: $specificTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }

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
                            ForEach(["Before Breakfast", "After Breakfast", "Before Lunch", "After Lunch"], id: \.self) { option in
                                Button(option) {
                                    selectedFoodOption = selectedFoodOption == option ? nil : option
                                }
                                .padding()
                                .background(selectedFoodOption == option ? Color.blue : Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                }

                // Additional Details Section
                VStack(alignment: .leading) {
                    Text("Additional details")
                        .font(.custom("RedditSans-Regular", size: 16))
                    TextEditor(text: $additionalDetails)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }

                // Error message
                if showErrorMessage {
                    Text("Please fill in all required fields.")
                        .foregroundColor(.red)
                        .font(.caption)
                }

                // Done Button
                Button(action: validateAndSubmit) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }

    private func validateAndSubmit() {
        guard !pillName.isEmpty, !pillAmount.isEmpty, !duration.isEmpty else {
            showErrorMessage = true
            return
        }

        showErrorMessage = false

        // Prepare pill data
        let pillData: [String: Any] = [
            "pillName": pillName,
            "amount": Int(pillAmount) ?? 0,
            "duration": Int(duration) ?? 0,
            "howOften": howOften,
            "specificTime": dateFormatter.string(from: specificTime),
            "foodInstruction": selectedFoodOption ?? "",
            "notificationBefore": notificationBefore,
            "additionalDetails": additionalDetails
        ]

        // Fetch UID from Firebase Auth
        if let uid = Auth.auth().currentUser?.uid {
            sendPillDataToBackend(uid: uid, pillData: pillData)
        } else {
            print("Error: User is not authenticated.")
        }
    }

    private func sendPillDataToBackend(uid: String, pillData: [String: Any]) {
        guard let url = URL(string: "http://localhost:3000/users/\(uid)/pills") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: pillData, options: [])
            request.httpBody = jsonData
        } catch {
            print("Failed to serialize JSON: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending pill data: \(error)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                print("Pill data successfully saved.")
            } else {
                print("Unexpected response from server.")
            }
        }.resume()
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
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

            HStack {
                Text("Repeat on")
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
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
    PlanView()
}
