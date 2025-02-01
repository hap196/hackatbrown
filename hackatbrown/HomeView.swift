import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(spacing: 20) {
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

            // Date selection
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<7) { index in
                        VStack {
                            Text(dayOfWeek(for: index))
                                .font(.custom("RedditSans-Regular", size: 14))
                                .foregroundColor(.gray)
                            Text("\(3 + index)")
                                .font(.custom("RedditSans-Bold", size: 16))
                                .foregroundColor(index == 4 ? .white : .black)
                                .padding(8)
                                .background(index == 4 ? Color(red: 0, green: 0.48, blue: 0.60) : Color.clear)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Circular progress
            CircularProgressView(progress: 0.75)
                .frame(width: 150, height: 150)
                .padding(.top)

            // Medication list
            VStack(spacing: 10) {
                MedicationItemView(name: "Oxycodon", time: "8:00 AM", dose: "2 pills", period: "Morning")
                MedicationItemView(name: "Lipitor", time: "10:00 AM", dose: "1 pill", period: "After Breakfast")
                MedicationItemView(name: "Omega 3", time: "12:00 AM", dose: "3 pills", period: "Before Lunch")
                MedicationItemView(name: "Naloxene", time: "2:00 PM", dose: "1 pill", period: "Afternoon")
            }

            Spacer()  // Push content up to match spacing from bottom
        }
        .padding(.top, 20)
        .background(Color.white)
        .ignoresSafeArea(edges: .bottom)
        .navigationBarHidden(true)  // Hide the default navigation bar
    }

    // Function to display days of the week dynamically
    private func dayOfWeek(for index: Int) -> String {
        let days = ["SAT", "SUN", "MON", "TUE", "WED", "THU", "FRI"]
        return days[index % days.count]
    }
}

// Circular progress view
struct CircularProgressView: View {
    var progress: Double  // Should be between 0.0 and 1.0

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

// Medication item row
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
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    HomeView()
}
