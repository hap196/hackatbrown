import SwiftUI

struct HomeView: View {
    @State private var currentDate = Date()         // Today’s date
    @State private var selectedDate = Date()          // Currently highlighted date
    @State private var weekOffset = 0                 // Current week page offset
    @State private var showCalendar = false           // Controls calendar sheet display

    var body: some View {
        ScrollView {  // Wrap everything in a vertical scroll view so that content can scroll on smaller screens.
            VStack(spacing: 12) {  // Reduced overall spacing
                // Top header with greeting and logo
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
                
                // Header showing the selected date in "Month Date, Year" format and a calendar button
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
                .padding(.top, 6) // Reduced top padding
                
                // Week swiping: each page represents a full week.
                TabView(selection: $weekOffset) {
                    ForEach(-100...100, id: \.self) { offset in
                        WeekView(weekOffset: offset, selectedDate: $selectedDate)
                            .tag(offset)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 110) // Reduced height for less vertical space between header and week selector.
                .onChange(of: weekOffset) { newOffset in
                    // When swiping to a new week, set the highlighted date to the first day of that week.
                    let newWeekStart = weekStart(for: newOffset)
                    selectedDate = newWeekStart
                }
                
                // Circular progress view remains unchanged.
                CircularProgressView(progress: 0.75)
                    .frame(width: 150, height: 150)
                    .padding(.top)
                
                // Extra spacing between the circle and the medication cards.
                Spacer().frame(height: 20)
                
                // Medication list with added horizontal padding.
                VStack(spacing: 10) {
                    MedicationItemView(name: "Oxycodon", time: "8:00 AM", dose: "2 pills", period: "Morning")
                    MedicationItemView(name: "Lipitor", time: "10:00 AM", dose: "1 pill", period: "After Breakfast")
                    MedicationItemView(name: "Omega 3", time: "12:00 AM", dose: "3 pills", period: "Before Lunch")
                    MedicationItemView(name: "Naloxene", time: "2:00 PM", dose: "1 pill", period: "Afternoon")
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 20)
            .background(Color.white)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarHidden(true)
        // Show the calendar sheet when toggled.
        .sheet(isPresented: $showCalendar) {
            CalendarSheet(selectedDate: $selectedDate, showCalendar: $showCalendar)
        }
        // If the user taps a day that isn’t in the current week, update the weekOffset accordingly.
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
    }
    
    // Returns the start date for the week at a given offset.
    private func weekStart(for offset: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: currentDate)
        return calendar.date(byAdding: .weekOfYear, value: offset, to: today) ?? today
    }
    
    // Returns a string for the header date in "MMMM d, yyyy" format.
    private func dateHeaderString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

// A sheet with a graphical DatePicker so users can jump to a specific date.
struct CalendarSheet: View {
    @Binding var selectedDate: Date
    @Binding var showCalendar: Bool

    var body: some View {
        NavigationView {
            VStack {
                // Smaller "Today" button placed at the top for easy access.
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
                    .padding(.trailing, 16) // Aligns with the date picker visually
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


// WeekView displays the seven days for a given week offset.
// The selected day now uses a filled background with a transparent blue (opacity 0.3).
// We also increased the spacing between the day label and number.
struct WeekView: View {
    let weekOffset: Int
    @Binding var selectedDate: Date

    var body: some View {
        HStack(spacing: 12) {
            ForEach(weekDates(for: weekOffset), id: \.self) { date in
                VStack(spacing: 8) {  // Increased spacing between day label and number.
                    Text(shortDayOfWeek(from: date))
                        .font(.custom("RedditSans-Regular", size: 14))
                        .foregroundColor(.gray)
                    Text(dayNumber(from: date))
                        .font(.custom("RedditSans-Bold", size: 16))
                        .foregroundColor(isSameDay(date1: date, date2: selectedDate) ? .white : .black)
                        .padding(12)  // Padding inside the circle.
                        .background(isSameDay(date1: date, date2: selectedDate) ?
                                    Color(red: 0, green: 0.48, blue: 0.60) :
                                    Color.clear)
                        .clipShape(Circle())
                        .frame(minWidth: 44, minHeight: 44) // Ensure a minimum size for alignment.
                        .onTapGesture {
                            selectedDate = date
                        }
                }
            }
        }
        .padding(.horizontal)
    }
    
    // Generate the dates for the week using the provided week offset.
    private func weekDates(for offset: Int) -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startOfWeek = calendar.date(byAdding: .weekOfYear, value: offset, to: today) ?? today
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    // Returns the abbreviated day of the week (e.g., "MON").
    private func shortDayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    // Returns the day number from the date.
    private func dayNumber(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    // Checks whether two dates are the same day.
    private func isSameDay(date1: Date, date2: Date) -> Bool {
        Calendar.current.isDate(date1, inSameDayAs: date2)
    }
}

// Circular progress view remains unchanged.
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

// Medication item view remains unchanged except for added horizontal padding.
struct MedicationItemView: View {
    var name: String
    var time: String
    var dose: String
    var period: String

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
        .padding() // Existing padding.
        .padding(.horizontal) // Added extra side padding.
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
