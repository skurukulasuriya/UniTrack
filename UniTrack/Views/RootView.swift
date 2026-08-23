import SwiftUI
import SwiftData

/// Shows the sign in screen until someone signs in, then the main interface.
struct RootView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.modelContext) private var context

    var body: some View {
        Group {
            if session.isSignedIn {
                StudentDirectoryView()
            } else {
                SignInView()
            }
        }
        .task {
            // Put the sample records in place the first time the app runs.
            SampleData.seedIfNeeded(context)
        }
    }
}
