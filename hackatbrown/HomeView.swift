import SwiftUI

// MARK: - IntakeLog Model
struct IntakeLog: Codable, Identifiable, Equatable {
    var id: String?            // Provided by the backend
    var date: Date
    var amount: Int
    var comments: String?
}

// MARK: - Pill Model
struct Pill: Codable, Identifiable, Equatable {
    let id: String
    var pillName: String
    var amount: Int
    var duration: Int           // Number of days the pill is scheduled
    var howOften: String
    var specificTime: String?
    var foodInstruction: String?
    var notificationBefore: String?
    var additionalDetails: String?
    var createdAt: Date?        // Provided by timestamps
    var intakeLogs: [IntakeLog]?    // New property for logging intake

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case pillName, amount, duration, howOften, specificTime, foodInstruction, notificationBefore, additionalDetails, createdAt, intakeLogs
    }
}

// MARK: - PillViewModel
class PillViewModel: ObservableObject {
    @Published var pills: [Pill] = []
    
    // Update these values as needed.
    let baseURL = "http://localhost:3000"
    let uid = "y3du4q4Ux0WhONouB7azVhKHPNR2"
    
    func fetchPills() async {
        guard let url = URL(string: "\(baseURL)/users/\(uid)/pills") else {
            print("Invalid URL")
            return
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let httpResp = response as? HTTPURLResponse, httpResp.statusCode != 200 {
                print("Server error, status: \(httpResp.statusCode)")
                return
            }
            let decoder = JSONDecoder()
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateStr = try container.decode(String.self)
                if let date = isoFormatter.date(from: dateStr) {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: container,
                                                       debugDescription: "Cannot decode date string \(dateStr)")
            }
            let pills = try decoder.decode([Pill].self, from: data)
            await MainActor.run {
                self.pills = pills
            }
        } catch {
            print("Error fetching pills: \(error.localizedDescription)")
        }
    }
    
    func updatePill(_ pill: Pill) async {
        guard let url = URL(string: "\(baseURL)/users/\(uid)/pills/\(pill.id)") else {
            print("Invalid URL for update")
            return
        }
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(pill)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 {
                print("Pill updated successfully")
            } else {
                print("Update failed")
            }
        } catch {
            print("Error updating pill: \(error.localizedDescription)")
        }
    }
    
    func deletePill(_ pill: Pill) async {
        guard let url = URL(string: "\(baseURL)/users/\(uid)/pills/\(pill.id)") else {
            print("Invalid URL for delete")
            return
        }
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 {
                print("Pill deleted successfully")
            } else {
                print("Delete failed")
            }
        } catch {
            print("Error deleting pill: \(error.localizedDescription)")
        }
    }
    
    // New function: Log an intake for a pill.
    func logPillIntake(pill: Pill, amountTaken: Int, comments: String, logDate: String) async {
        guard let url = URL(string: "\(baseURL)/users/\(uid)/pills/\(pill.id)/intake") else {
            print("Invalid URL for intake")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let intakeData: [String: Any] = [
            "amountTaken": amountTaken,
            "comments": comments,
            "logDate": logDate
        ]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: intakeData, options: []) else {
            print("Error encoding intake data")
            return
        }
        request.httpBody = httpBody
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 {
                print("Intake logged successfully")
            } else {
                print("Intake logging failed")
            }
        } catch {
            print("Error logging intake: \(error.localizedDescription)")
        }
    }

}

// MARK: - HomeView
struct HomeView: View {
    // For testing, set currentDate to Feb 1, 2025.
    @State private var currentDate = Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 1)) ?? Date()
    @State private var selectedDate = Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 1)) ?? Date()
    @State private var weekOffset = 0
    @State private var showCalendar = false
    @State private var selectedPill: Pill? = nil
    
    @StateObject private var pillVM = PillViewModel()
    
    private var dailyProgress: Double {
            let pills = pillsForSelectedDate()
            let totalRequired = pills.reduce(0) { $0 + $1.amount }
            let totalLogged = pills.reduce(0) { $0 + getLoggedAmount(for: $1, on: selectedDate) }
            guard totalRequired > 0 else { return 0 }
            let progress = Double(totalLogged) / Double(totalRequired)
            return min(progress, 1.0)
        }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    // Header and Calendar Button (same as before)
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Hello,")
                                .font(.custom("RedditSans-Bold", size: 28))
                                .foregroundColor(Color(red: 0, green: 0.48, blue: 0.60))
                            Text("John")
                                .font(.custom("RedditSans-Regular", size: 28))
                                .foregroundColor(Color(red: 0.251, green: 0.251, blue: 0.251))
                        }
                        Spacer()
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .padding(.trailing)
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Text(dateHeaderString(for: selectedDate))
                            .font(.custom("RedditSans-Bold", size: 20))
                            .foregroundColor(.black)
                        Spacer()
                        Button {
                            showCalendar.toggle()
                        } label: {
                            Image(systemName: "calendar")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 6)
                    
                    // Week swiping.
                    TabView(selection: $weekOffset) {
                        ForEach(-100...100, id: \.self) { offset in
                            WeekView(weekOffset: offset, selectedDate: $selectedDate)
                                .tag(offset)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 110)
                    .onChange(of: weekOffset) { newOffset in
                        let newWeekStart = weekStart(for: newOffset)
                        selectedDate = newWeekStart
                    }
                    
                    // Updated Circular Progress View:
                    CircularProgressView(progress: dailyProgress)
                        .frame(width: 150, height: 150)
                        .padding(.top)
                                       
                    Spacer().frame(height: 20)
                    
                    // Medication list: each card now determines its background based on completion.
                                        VStack(spacing: 10) {
                                            ForEach(pillsForSelectedDate(), id: \.id) { pill in
                                                let logged = getLoggedAmount(for: pill, on: selectedDate)
                                                let completed = logged >= pill.amount
                                                MedicationItemView(
                                                    name: pill.pillName,
                                                    time: pill.specificTime ?? "N/A",
                                                    dose: "\(logged)/\(pill.amount)",
                                                    period: pill.foodInstruction ?? "",
                                                    completed: completed
                                                )
                                                .onTapGesture {
                                                    selectedPill = pill
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                        
                                        Spacer()
                }
                .padding(.top, 20)
                .background(Color.white)
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationBarHidden(true)
            .sheet(isPresented: $showCalendar) {
                CalendarSheet(selectedDate: $selectedDate, showCalendar: $showCalendar)
            }
            .sheet(item: $selectedPill) { pill in
                PillDetailView(viewModel: pillVM, pill: pill, logDate: selectedDate)
            }
            .onChange(of: selectedDate) { newDate in
                let calendar = Calendar.current
                if let newWeekStart = calendar.dateInterval(of: .weekOfYear, for: newDate)?.start {
                    let currentWeekStart = weekStart(for: weekOffset)
                    if !calendar.isDate(newWeekStart, inSameDayAs: currentWeekStart) {
                        if let weeksDifference = calendar.dateComponents([.weekOfYear], from: currentWeekStart, to: newWeekStart).weekOfYear {
                            weekOffset += weeksDifference
                        }
                    }
                }
            }
            .task {
                await pillVM.fetchPills()
            }
        }
    }
    
    private func weekStart(for offset: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: currentDate)
        return calendar.date(byAdding: .weekOfYear, value: offset, to: today) ?? today
    }
    
    private func dateHeaderString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    // Filter pills as before.
    private func pillsForSelectedDate() -> [Pill] {
        let calendar = Calendar.current
        let selectedStart = calendar.startOfDay(for: selectedDate)
        return pillVM.pills.filter { pill in
            guard let createdAt = pill.createdAt else { return false }
            let pillStart = calendar.startOfDay(for: createdAt)
            guard let rawEnd = calendar.date(byAdding: .day, value: pill.duration, to: createdAt) else { return false }
            let pillEnd = calendar.startOfDay(for: rawEnd)
            guard selectedStart >= pillStart && selectedStart <= pillEnd else { return false }
            if pill.howOften.lowercased() == "daily" {
                return true
            } else if pill.howOften.lowercased() == "weekly" {
                let pillWeekday = calendar.component(.weekday, from: pillStart)
                let selectedWeekday = calendar.component(.weekday, from: selectedStart)
                return pillWeekday == selectedWeekday
            } else {
                return true
            }
        }
    }
    
    // Helper to compute the logged intake for a pill on a given day.
    private func getLoggedAmount(for pill: Pill, on date: Date) -> Int {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        return pill.intakeLogs?
            .filter { calendar.isDate($0.date, inSameDayAs: dayStart) }
            .map { $0.amount }
            .reduce(0, +) ?? 0
    }
}

// MARK: - PillDetailView
struct PillDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: PillViewModel
    @State var pill: Pill
    let logDate: Date    // This is the selected date from HomeView

    @State private var isEditing = false

    // Editable fields with context labels.
    @State private var pillName: String = ""
    @State private var pillAmount: String = ""
    @State private var duration: String = ""
    @State private var howOften: String = ""
    @State private var specificTime: String = ""
    @State private var foodInstruction: String = ""
    @State private var notificationBefore: String = ""
    @State private var additionalDetails: String = ""

    // New intake logging fields.
    @State private var intakeAmount: String = "" // No autopopulation now.
    @State private var intakeComments: String = ""

    let notificationOptions = ["No Notification", "5 minutes before", "10 minutes before", "15 minutes before", "30 minutes before", "1 hour before", "2 hours before"]
    let frequencyOptions = ["Daily", "Weekly"]

    // Helper: Total intake for logDate
    private var totalTakenToday: Int {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: logDate)
        return pill.intakeLogs?
            .filter { calendar.isDate($0.date, inSameDayAs: dayStart) }
            .map { $0.amount }
            .reduce(0, +) ?? 0
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Pill Info")
                            .font(.custom("RedditSans-Bold", size: 18))
                            .foregroundColor(Color(red: 0, green: 0.48, blue: 0.60))) {
                    HStack {
                        Text("Pill Name:")
                            .font(.custom("RedditSans-Regular", size: 16))
                        Spacer()
                        if isEditing {
                            TextField("Pill Name", text: $pillName)
                                .multilineTextAlignment(.trailing)
                                .font(.custom("RedditSans-Regular", size: 16))
                        } else {
                            Text(pillName)
                                .font(.custom("RedditSans-Regular", size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                    HStack {
                        Text("Amount:")
                            .font(.custom("RedditSans-Regular", size: 16))
                        Spacer()
                        if isEditing {
                            TextField("Amount", text: $pillAmount)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .font(.custom("RedditSans-Regular", size: 16))
                        } else {
                            Text(pillAmount)
                                .font(.custom("RedditSans-Regular", size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                    HStack {
                        Text("Duration (days):")
                            .font(.custom("RedditSans-Regular", size: 16))
                        Spacer()
                        if isEditing {
                            TextField("Duration", text: $duration)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .font(.custom("RedditSans-Regular", size: 16))
                        } else {
                            Text(duration)
                                .font(.custom("RedditSans-Regular", size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                    HStack {
                        Text("Frequency:")
                            .font(.custom("RedditSans-Regular", size: 16))
                        Spacer()
                        if isEditing {
                            Picker("", selection: $howOften) {
                                ForEach(frequencyOptions, id: \.self) { option in
                                    Text(option)
                                        .font(.custom("RedditSans-Regular", size: 16))
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        } else {
                            Text(howOften)
                                .font(.custom("RedditSans-Regular", size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("Time & Notification")
                            .font(.custom("RedditSans-Bold", size: 18))
                            .foregroundColor(Color(red: 0, green: 0.48, blue: 0.60))) {
                    HStack {
                        Text("Specific Time:")
                            .font(.custom("RedditSans-Regular", size: 16))
                        Spacer()
                        if isEditing {
                            TextField("Specific Time", text: $specificTime)
                                .multilineTextAlignment(.trailing)
                                .font(.custom("RedditSans-Regular", size: 16))
                        } else {
                            Text(specificTime)
                                .font(.custom("RedditSans-Regular", size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                    HStack {
                        Text("Notification:")
                            .font(.custom("RedditSans-Regular", size: 16))
                        Spacer()
                        if isEditing {
                            Picker("", selection: $notificationBefore) {
                                ForEach(notificationOptions, id: \.self) { option in
                                    Text(option)
                                        .font(.custom("RedditSans-Regular", size: 16))
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        } else {
                            Text(notificationBefore)
                                .font(.custom("RedditSans-Regular", size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("Additional Info")
                            .font(.custom("RedditSans-Bold", size: 18))
                            .foregroundColor(Color(red: 0, green: 0.48, blue: 0.60))) {
                    HStack {
                        Text("Food Instruction:")
                            .font(.custom("RedditSans-Regular", size: 16))
                        Spacer()
                        if isEditing {
                            TextField("Food Instruction", text: $foodInstruction)
                                .multilineTextAlignment(.trailing)
                                .font(.custom("RedditSans-Regular", size: 16))
                        } else {
                            Text(foodInstruction)
                                .font(.custom("RedditSans-Regular", size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("Details:")
                            .font(.custom("RedditSans-Regular", size: 16))
                        if isEditing {
                            TextEditor(text: $additionalDetails)
                                .frame(height: 100)
                        } else {
                            Text(additionalDetails)
                                .font(.custom("RedditSans-Regular", size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Intake Logging Section
                Section(header: Text("Log Intake")
                            .font(.custom("RedditSans-Bold", size: 18))
                            .foregroundColor(Color(red: 0, green: 0.48, blue: 0.60))) {
                    HStack {
                        Text("Total Taken Today:")
                            .font(.custom("RedditSans-Regular", size: 16))
                        Spacer()
                        Text("\(totalTakenToday)")
                            .font(.custom("RedditSans-Regular", size: 16))
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Amount Taken:")
                            .font(.custom("RedditSans-Regular", size: 16))
                        Spacer()
                        // This field now uses a number pad and remains blank by default.
                        TextField("Enter amount", text: $intakeAmount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.custom("RedditSans-Regular", size: 16))
                    }
                    VStack(alignment: .leading) {
                        Text("Comments:")
                            .font(.custom("RedditSans-Regular", size: 16))
                        TextEditor(text: $intakeComments)
                            .frame(height: 80)
                            .font(.custom("RedditSans-Regular", size: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                    }
                    Button(action: {
                        Task {
                            await logIntake()
                        }
                    }) {
                        Text("Log Intake")
                            .font(.custom("RedditSans-Bold", size: 16))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(red: 0, green: 0.48, blue: 0.60))
                            .cornerRadius(8)
                    }
                }
                
                if isEditing {
                    Section {
                        Button(action: {
                            Task {
                                await updatePill()
                            }
                        }) {
                            Text("Save Changes")
                                .font(.custom("RedditSans-Bold", size: 16))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.white)
                        }
                        .listRowBackground(Color(red: 0, green: 0.48, blue: 0.60))
                    }
                }
                
                Section {
                    Button(role: .destructive, action: {
                        Task {
                            await deletePill()
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Delete Pill")
                                .font(.custom("RedditSans-Bold", size: 16))
                            Spacer()
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Cancel" : "Edit") {
                        if isEditing { loadPillData() }
                        isEditing.toggle()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadPillData()
            }
        }
    }
    
    private func loadPillData() {
        pillName = pill.pillName
        pillAmount = "\(pill.amount)"
        duration = "\(pill.duration)"
        howOften = pill.howOften
        specificTime = pill.specificTime ?? ""
        foodInstruction = pill.foodInstruction ?? ""
        notificationBefore = pill.notificationBefore ?? ""
        additionalDetails = pill.additionalDetails ?? ""
        
        // Do not autopopulate intakeAmount so the user must enter a new value.
        intakeAmount = ""
        // However, you may choose to preload intakeComments if desired (or leave it blank).
        // Here, we'll leave intakeComments as-is.
    }
    
    private func updatePill() async {
        guard let amountInt = Int(pillAmount), let durationInt = Int(duration) else { return }
        pill.pillName = pillName
        pill.amount = amountInt
        pill.duration = durationInt
        pill.howOften = howOften
        pill.specificTime = specificTime
        pill.foodInstruction = foodInstruction
        pill.notificationBefore = notificationBefore
        pill.additionalDetails = additionalDetails
        
        await viewModel.updatePill(pill)
        await viewModel.fetchPills()
        isEditing = false
        dismiss()
    }
    
    private func deletePill() async {
        await viewModel.deletePill(pill)
        await viewModel.fetchPills()
        dismiss()
    }
    
    private func logIntake() async {
        guard let amountInt = Int(intakeAmount) else {
            print("Invalid intake amount")
            return
        }
        let formatter = ISO8601DateFormatter()
        let logDateString = formatter.string(from: logDate)
        
        await viewModel.logPillIntake(pill: pill, amountTaken: amountInt, comments: intakeComments, logDate: logDateString)
        
        await viewModel.fetchPills() // Refresh pill list to update logs
        
        // Dismiss the detail view after logging intake.
        dismiss()
    }
}

// MARK: - CalendarSheet, WeekView, CircularProgressView, MedicationItemView
struct CalendarSheet: View {
    @Binding var selectedDate: Date
    @Binding var showCalendar: Bool

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        selectedDate = Date()
                    }) {
                        Text("Today")
                            .font(.custom("RedditSans-Regular", size: 14))
                            .padding(6)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    .padding(.trailing, 16)
                }
                
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Choose a Date")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showCalendar = false
                    }
                }
            }
        }
    }
}

struct WeekView: View {
    let weekOffset: Int
    @Binding var selectedDate: Date

    var body: some View {
        HStack(spacing: 12) {
            ForEach(weekDates(for: weekOffset), id: \.self) { date in
                VStack(spacing: 8) {
                    Text(shortDayOfWeek(from: date))
                        .font(.custom("RedditSans-Regular", size: 14))
                        .foregroundColor(.gray)
                    Text(dayNumber(from: date))
                        .font(.custom("RedditSans-Bold", size: 16))
                        .foregroundColor(isSameDay(date1: date, date2: selectedDate) ? .white : .black)
                        .padding(12)
                        .background(isSameDay(date1: date, date2: selectedDate) ?
                                    Color(red: 0, green: 0.48, blue: 0.60).opacity(0.3) :
                                    Color.clear)
                        .clipShape(Circle())
                        .frame(minWidth: 44, minHeight: 44)
                        .onTapGesture {
                            selectedDate = date
                        }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func weekDates(for offset: Int) -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startOfWeek = calendar.date(byAdding: .weekOfYear, value: offset, to: today) ?? today
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    private func shortDayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private func dayNumber(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func isSameDay(date1: Date, date2: Date) -> Bool {
        Calendar.current.isDate(date1, inSameDayAs: date2)
    }
}

// MARK: - CircularProgressView (Modified)
struct CircularProgressView: View {
    var progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.green.opacity(0.3), lineWidth: 14)
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.custom("RedditSans-Bold", size: 24))
                .foregroundColor(Color.green)
        }
    }
}


// MARK: - MedicationItemView (Modified)
struct MedicationItemView: View {
    var name: String
    var time: String
    var dose: String
    var period: String
    var completed: Bool    // New property

    var body: some View {
        HStack {
            Image(systemName: "pills.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(.green)
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.custom("RedditSans-Bold", size: 16))
                    .foregroundColor(.black)
                Text("\(time)   |   \(dose)   |   \(period)")
                    .font(.custom("RedditSans-Regular", size: 14))
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .padding(.horizontal)
        // Use green background if completed; otherwise, gray.
        .background(completed ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
