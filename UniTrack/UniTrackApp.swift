import SwiftUI
import SwiftData

/// Entry point for UniTrack, a student record system for ECU staff and students.
@main
struct UniTrackApp: App {

    /// One session for the whole app, holding the signed-in user and their role.
    @State private var session = SessionStore()

    /// SwiftData stack. Every model type has to be listed here or queries for it
    /// will fail at runtime.
    private let container: ModelContainer = Self.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                // One accent for the whole app, matching the report's table headers.
                .tint(.uniTrackAccent)
        }
        .modelContainer(container)
        .defaultSize(width: 1180, height: 820)
        .windowToolbarStyle(.unified)
    }

    private static var schema: Schema {
        Schema([
            Student.self,
            Course.self,
            Unit.self,
            Enrolment.self,
            UserAccount.self,
        ])
    }

    /// Where the database file lives.
    ///
    /// This is deliberately a folder of our own rather than the default, which
    /// drops a `default.store` straight into Application Support where it can
    /// collide with other apps' stores.
    private static var storeURL: URL {
        let base = URL.applicationSupportDirectory.appending(path: "UniTrack", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appending(path: "UniTrack.store")
    }

    /// Opens the store, with two fallbacks so a bad database can't make the app
    /// unlaunchable.
    ///
    /// If the store on disk can't be opened — usually an old copy left over from
    /// an earlier version of the model — it gets moved aside and a fresh one is
    /// created. Only if that also fails do we drop to an in-memory store, which
    /// at least lets the app run.
    private static func makeContainer() -> ModelContainer {
        let configuration = ModelConfiguration(url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            moveStoreAside()
        }

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            // Last resort: run without saving anything to disk.
            let memoryOnly = ModelConfiguration(isStoredInMemoryOnly: true)
            // If even this fails the schema itself is wrong, which is a
            // programming error rather than something to recover from.
            return try! ModelContainer(for: schema, configurations: memoryOnly)
        }
    }

    /// Renames the existing store files so a clean one can be created, keeping
    /// the old data around rather than deleting it outright.
    private static func moveStoreAside() {
        let manager = FileManager.default
        let stamp = ISO8601DateFormatter().string(from: .now).replacingOccurrences(of: ":", with: "-")
        let directory = storeURL.deletingLastPathComponent()
        let name = storeURL.lastPathComponent

        // SQLite keeps a write-ahead log and shared memory file next to the store,
        // and all three have to move together or the new store inherits the old state.
        for suffix in ["", "-wal", "-shm"] {
            let source = directory.appending(path: name + suffix)
            // Has to be the unencoded path here. URL.path() percent-encodes, so
            // "Application Support" comes back as "Application%20Support" and
            // FileManager reports the file as missing.
            guard manager.fileExists(atPath: source.path(percentEncoded: false)) else { continue }
            let backup = directory.appending(path: "\(name).\(stamp).backup\(suffix)")
            try? manager.moveItem(at: source, to: backup)
        }
    }
}
