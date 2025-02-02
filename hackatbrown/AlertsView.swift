import SwiftUI

// MARK: - AlertItem Model
struct AlertItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let time: String  // e.g. "1 missing" or "2 extra"
    let logDate: Date
}

// MARK: - AlertsView
struct AlertsView: View {
    @StateObject private var pillVM = PillViewModel()
    
    // Compute all alerts from the intake logs on all pills, sorted by logDate descending.
    private var allAlerts: [AlertItem] {
        var alerts: [AlertItem] = []
        let calendar = Calendar.current
        
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
                                          logDate: day)
                    alerts.append(alert)
                } else if totalLogged > pill.amount {
                    let extra = totalLogged - pill.amount
                    let alert = AlertItem(icon: "exclamationmark.circle",
                                          title: "Over dosage: \(pill.pillName)",
                                          time: "\(extra) extra",
                                          logDate: day)
                    alerts.append(alert)
                }
            }
        }
        return alerts.sorted { $0.logDate > $1.logDate }
    }
    
    // Separate alerts into those in the current week and those in the past.
    private var thisWeekAlerts: [AlertItem] {
        let calendar = Calendar.current
        return allAlerts.filter { calendar.isDate($0.logDate, equalTo: Date(), toGranularity: .weekOfYear) }
    }
    private var pastAlerts: [AlertItem] {
        let calendar = Calendar.current
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
                SectionView(sectionTitle: "This Week", alerts: thisWeekAlerts)
                
                // Past Section
                SectionView(sectionTitle: "Past", alerts: pastAlerts)
                
                Spacer()
            }
            .padding(.bottom)
        }
        .background(Color.white)
        .task {
            await pillVM.fetchPills()
        }
    }
}

// Component for displaying sections.
struct SectionView: View {
    let sectionTitle: String
    let alerts: [AlertItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(sectionTitle)
                .font(.custom("RedditSans-Bold", size: 20))
                .foregroundColor(Color(red: 0.13, green: 0.13, blue: 0.18))
                .padding(.horizontal)
            
            ForEach(alerts) { alert in
                AlertRowView(alert: alert)
                    .padding(.horizontal)
            }
            
            Divider()
                .padding(.horizontal)
        }
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
