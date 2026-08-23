import SwiftUI
import SwiftData

/// Entry point for UniTrack, a student record system for ECU staff and students.
@main
struct UniTrackApp: App {

    /// One session for the whole app, holding the signed-in user and their role.
    @State private var session = SessionStore()

    /// SwiftData stack. Every model type has to be listed here or queries for it
    /// will fail at runtime.
    private let container: ModelContainer = {
        let schema = Schema([
            Student.self,
            Course.self,
            Unit.self,
            Enrolment.self,
            UserAccount.self,
        ])
        do {
            return try ModelContainer(for: schema)
        } catch {
            // Nothing sensible to fall back on if the store won't open.
            fatalError("Could not create the model container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
        }
        .modelContainer(container)
        .defaultSize(width: 1000, height: 660)
        .windowToolbarStyle(.unified)
    }
}
