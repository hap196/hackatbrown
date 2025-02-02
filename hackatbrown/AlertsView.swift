import SwiftUI

// MARK: - AlertItem Model
struct AlertItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let time: String  // e.g. "1 missing" or "2 extra"
    let logDate: Date
    let recommendedDosage: Int
    let yourDosage: Int
}

// MARK: - AlertsView
struct AlertsView: View {
    @StateObject private var pillVM = PillViewModel()
    @State private var selectedAlert: AlertItem? = nil  // Track selected alert
    let calendar = Calendar.current
    
    // Compute all alerts from the intake logs on all pills, sorted by logDate descending.
    private var allAlerts: [AlertItem] {
        var alerts: [AlertItem] = []
        
        for pill in pillVM.pills {
            guard let logs = pill.intakeLogs, !logs.isEmpty else { continue }
            
            // Group intake logs by day.
            let grouped = Dictionary(grouping: logs) { log in
                calendar.startOfDay(for: log.date)
            }
            for (day, logsForDay) in grouped {
                let totalLogged = logsForDay.map { $0.amount }.reduce(0, +)
                if totalLogged < pill.amount {
                    let missing = pill.amount - totalLogged
                    let alert = AlertItem(icon: "exclamationmark.triangle",
                                          title: "Missing pill: \(pill.pillName)",
                                          time: "\(missing) missing",
                                          logDate: day,
                                          recommendedDosage: pill.amount,
                                          yourDosage: totalLogged)
                    alerts.append(alert)
                } else if totalLogged > pill.amount {
                    let extra = totalLogged - pill.amount
                    let alert = AlertItem(icon: "exclamationmark.circle",
                                          title: "Over dosage: \(pill.pillName)",
                                          time: "\(extra) extra",
                                          logDate: day,
                                          recommendedDosage: pill.amount,
                                          yourDosage: totalLogged)
                    alerts.append(alert)
                }
            }
        }
        return alerts.sorted { $0.logDate > $1.logDate }
    }
    
    // Separate alerts into those in the current week and those in the past.
    private var thisWeekAlerts: [AlertItem] {
        return allAlerts.filter { calendar.isDate($0.logDate, equalTo: Date(), toGranularity: .weekOfYear) }
    }
    private var pastAlerts: [AlertItem] {
        return allAlerts.filter { !calendar.isDate($0.logDate, equalTo: Date(), toGranularity: .weekOfYear) }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                Text("Alerts")
                    .font(.custom("RedditSans-Bold", size: 28))
                    .foregroundColor(Color(red: 0, green: 0.48, blue: 0.60))
                    .padding(.top, 10)
                    .padding(.horizontal)
                
                // This Week Section
                SectionView(sectionTitle: "This Week", alerts: thisWeekAlerts, selectedAlert: $selectedAlert)
                
                // Past Section
                SectionView(sectionTitle: "Past", alerts: pastAlerts, selectedAlert: $selectedAlert)
                
                Spacer()
            }
            .padding(.bottom)
        }
        .background(Color.white)
        .sheet(item: $selectedAlert) { alert in
            AlertDetailView(alert: alert)
        }
        .task {
            await pillVM.fetchPills()
        }
    }
}

// Component for displaying a section of alerts.
struct SectionView: View {
    let sectionTitle: String
    let alerts: [AlertItem]
    @Binding var selectedAlert: AlertItem?  // Binding to open the detail view
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(sectionTitle)
                .font(.custom("RedditSans-Bold", size: 20))
                .foregroundColor(Color(red: 0.13, green: 0.13, blue: 0.18))
                .padding(.horizontal)
            
            ForEach(alerts) { alert in
                Button {
                    selectedAlert = alert  // Open the detail view
                } label: {
                    AlertRowView(alert: alert)
                        .padding(.horizontal)
                }
            }
            
            Divider()
                .padding(.horizontal)
        }
    }
}

// A view model that simulates fetching an explanation and severity rating via OpenAI API.
class AlertDetailViewModel: ObservableObject {
    @Published var explanation: String = ""
    @Published var severity: Double = 0.0  // 0 to 10

    func fetchExplanation(for alert: AlertItem) async {
        // Construct a prompt using alert information.
        let prompt = """
        Provide a short explanation for the following alert and rate its severity on a scale of 0 to 10.
        Alert: \(alert.title) (\(alert.time))
        Recommended dosage: \(alert.recommendedDosage)
        Your logged dosage: \(alert.yourDosage)
        Explain the potential health impact.
        Respond in the following format:
        Explanation: [Your explanation here]
        Severity: [number]/10
        """

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            print("Invalid OpenAI URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let apiKey: String = {
            if let key = Bundle.main.object(forInfoDictionaryKey: "OpenAIAPIKey") as? String {
                return key
            } else {
                fatalError("OpenAIAPIKey not set in Info.plist")
            }
        }()

        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Prepare the request body for the Chat Completions API.
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                [
                    "role": "system",
                    "content": "You are a helpful assistant that provides dosage explanations and severity ratings."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 150
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            print("Error encoding OpenAI request body")
            return
        }
        request.httpBody = httpBody

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 {
                // Parse the JSON response.
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {

                    DispatchQueue.main.async {
                        self.explanation = content
                        
                        // Extract severity from the response
                        if let severityRange = content.range(of: "Severity: ") {
                            let severitySubstring = content[severityRange.upperBound...]
                            let severityString = severitySubstring.prefix { "0123456789".contains($0) }
                            if let severityValue = Double(severityString) {
                                self.severity = severityValue
                            }
                        }
                    }
                } else {
                    print("Failed to parse OpenAI response")
                }
            } else {
                print("OpenAI API call failed")
                if let httpResp = response as? HTTPURLResponse {
                    print("HTTP Status Code: \(httpResp.statusCode)")
                }
            }
        } catch {
            print("Error in OpenAI API call: \(error.localizedDescription)")
        }
    }
    
}

import SwiftUI

struct AlertDetailView: View {
    let alert: AlertItem
    @StateObject private var viewModel = AlertDetailViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Title Section
                Text(alert.title)
                    .font(.custom("RedditSans-Bold", size: 24))
                    .foregroundColor(Color(red: 0, green: 0.48, blue: 0.60))
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)

                // Dosage Information Section
                VStack(spacing: 12) {
                    InfoRowView(label: "Recommended Dosage:", value: "\(alert.recommendedDosage)")
                    InfoRowView(label: "Your Dosage:", value: "\(alert.yourDosage)")
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)

                // Explanation Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Explanation")
                        .font(.custom("RedditSans-Bold", size: 20))
                        .foregroundColor(Color(red: 0, green: 0.48, blue: 0.60))
                    
                    Text(viewModel.explanation.isEmpty ? "Loading explanation..." : viewModel.explanation)
                        .font(.custom("RedditSans-Regular", size: 16))
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)

                // Severity Section
                VStack(spacing: 10) {
                    HStack {
                        Text("Severity:")
                            .font(.custom("RedditSans-Bold", size: 18))
                        Spacer()
                        Text("\(Int(viewModel.severity))/10")
                            .font(.custom("RedditSans-Bold", size: 18))
                            .foregroundColor(viewModel.severity > 7 ? .red : .gray)
                    }
                    
                    ProgressView(value: viewModel.severity, total: 10)
                        .progressViewStyle(LinearProgressViewStyle(tint: viewModel.severity > 7 ? .red : .green))
                        .padding(.top, 4)
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)

                // Call Emergency Button
                Button(action: { /* Add emergency call logic */ }) {
                    Text("Call 911")
                        .font(.custom("RedditSans-Bold", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(8)
                }

                Spacer()
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .onAppear {
            Task {
                await viewModel.fetchExplanation(for: alert)
            }
        }
    }
}

// Reusable row for displaying key-value pairs
struct InfoRowView: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.custom("RedditSans-Regular", size: 18))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.custom("RedditSans-Bold", size: 18))
                .foregroundColor(.black)
        }
    }
}

struct AlertDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let dummyAlert = AlertItem(icon: "exclamationmark.triangle",
                                   title: "Missing pill: Omega 3",
                                   time: "1 missing",
                                   logDate: Date(),
                                   recommendedDosage: 2,
                                   yourDosage: 1)
        AlertDetailView(alert: dummyAlert)
    }
}


// Component for each alert row.
struct AlertRowView: View {
    let alert: AlertItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: alert.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.custom("RedditSans-Bold", size: 16))
                    .foregroundColor(.black)
                
                HStack {
                    Text(alert.time)
                    Spacer()
                    Text(dateString(from: alert.logDate))
                }
                .font(.custom("RedditSans-Regular", size: 14))
                .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
    }
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}



struct AlertsView_Previews: PreviewProvider {
    static var previews: some View {
        AlertsView()
    }
}
