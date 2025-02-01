import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel  // Access the auth state

    var body: some View {
        VStack {
            Text("Settings")
                .font(.largeTitle)

            Button(action: {
                authViewModel.signOut()
            }) {
                Text("Log Out")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}
