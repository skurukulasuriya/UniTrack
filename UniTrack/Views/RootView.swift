import SwiftUI
import SwiftData

/// Decides which screen to show: first run setup, sign in, or the app itself.
struct RootView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.modelContext) private var context
    @Query private var accounts: [UserAccount]

    var body: some View {
        Group {
            if accounts.isEmpty {
                // No logins exist yet, so there's nothing to sign in to.
                FirstRunSetupView()
            } else if session.isSignedIn {
                MainView()
            } else {
                SignInView()
            }
        }
        .task {
            // Put the sample academic records in place the first time the app runs.
            SampleData.seedIfNeeded(context)
        }
    }
}
