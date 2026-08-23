import Foundation
import SwiftData

#if DEBUG
/// Debug-only helper for getting the app into a signed-in state without typing.
///
/// Used when capturing screenshots for the report, where synthetic keystrokes
/// are blocked by the system. Run with `-UniTrackDemo YES` to enable it.
///
/// The password is generated randomly on every launch and thrown away, so there
/// is still no fixed credential anywhere in the source. Wrapped in `#if DEBUG`
/// so none of this exists in a release build.
enum DemoMode {

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "UniTrackDemo")
    }

    /// Makes an administrator and a general user, then signs in as whichever
    /// role was asked for with `-UniTrackDemoRole admin|general`.
    @MainActor
    static func prepare(session: SessionStore, context: ModelContext) {
        guard isEnabled else { return }

        let existing = (try? context.fetch(FetchDescriptor<UserAccount>())) ?? []
        guard existing.isEmpty else {
            signIn(session: session, accounts: existing)
            return
        }

        // Random each launch - nothing reusable ends up in the repository.
        let adminPassword = randomPassword()
        let generalPassword = randomPassword()

        // Link the general login to a real student so the "own record only"
        // rule has something to resolve to.
        let students = (try? context.fetch(FetchDescriptor<Student>())) ?? []
        let linked = students.sorted { $0.studentID < $1.studentID }.first

        guard let admin = try? UserAccount(username: "records",
                                           displayName: "Records Administrator",
                                           role: .admin,
                                           password: adminPassword),
              let general = try? UserAccount(username: linked?.givenName.lowercased() ?? "student",
                                             displayName: linked?.fullName ?? "General User",
                                             role: .general,
                                             password: generalPassword,
                                             student: linked)
        else { return }

        context.insert(admin)
        context.insert(general)
        try? context.save()

        let wanted = UserDefaults.standard.string(forKey: "UniTrackDemoRole") ?? "admin"
        if wanted == "general" {
            session.signIn(username: general.username, password: generalPassword, accounts: [general])
        } else {
            session.signIn(username: admin.username, password: adminPassword, accounts: [admin])
        }
    }

    /// Re-signs in on a later launch, when the accounts already exist but the
    /// generated passwords are long gone.
    @MainActor
    private static func signIn(session: SessionStore, accounts: [UserAccount]) {
        let wanted = UserDefaults.standard.string(forKey: "UniTrackDemoRole") ?? "admin"
        let role: Role = wanted == "general" ? .general : .admin
        guard let account = accounts.first(where: { $0.role == role }) else { return }

        // The stored hash can't be reversed, so give the account a fresh random
        // password and use that to sign in through the normal path.
        let password = randomPassword()
        if let credential = try? PasswordHasher.makeCredential(for: password) {
            account.salt = credential.salt
            account.iterations = credential.iterations
            account.credentialHash = credential.hash
            session.signIn(username: account.username, password: password, accounts: [account])
        }
    }

    private static func randomPassword() -> String {
        let characters = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<20).map { _ in characters.randomElement()! })
    }
}
#endif
