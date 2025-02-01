import SwiftUI

struct LandingView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()  // Pushes everything to the middle

                // App Logo and Text
                VStack(spacing: 20) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)

                    Text("MediGuard")
                        .font(.custom("RedditSans-Bold", size: 32))
                        .foregroundColor(Color(red: 0, green: 0.48, blue: 0.60))

                    Text("Your Personal Medication Safety Companion")
                        .font(.custom("RedditSans-Regular", size: 16))
                        .foregroundColor(Color(red: 0.251, green: 0.251, blue: 0.251))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)  // For better readability on small screens
                }

                Spacer()  // Balances the vertical alignment

                // Navigation Buttons
                VStack(spacing: 10) {
                    NavigationLink(destination: LoginView()) {
                        Text("Login")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0, green: 0.48, blue: 0.60))
                            .cornerRadius(8)
                    }

                    NavigationLink(destination: SignUpView()) {
                        Text("Sign up")
                            .font(.headline)
                            .foregroundColor(Color(red: 0, green: 0.48, blue: 0.60))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(red: 0, green: 0.48, blue: 0.60), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .frame(maxHeight: .infinity)  // Ensures dynamic spacing
            .padding()
        }
    }
}
