import Foundation
import CryptoKit
import SwiftUI

/// Holds who is signed in and what they're allowed to do.
///
/// Every check on whether an edit is permitted goes through here, so the rule
/// lives in one place instead of being repeated across the views.
@Observable
final class SessionStore {

    /// The signed-in account, or nil when nobody is signed in.
    private(set) var currentUser: UserAccount?
    /// Set when a sign in attempt fails, so the view can show a message.
    private(set) var lastError: String?

    var isSignedIn: Bool { currentUser != nil }

    /// Role of whoever is signed in. Defaults to the least privileged option so
    /// a missing session can never accidentally grant admin access.
    var role: Role { currentUser?.role ?? .general }

    /// Whether the current user may change stored records.
    var canEditRecords: Bool { isSignedIn && role.canEditRecords }

    /// Hashes a passphrase for comparison against a stored credential.
    static func hash(_ passphrase: String) -> Data {
        Data(SHA256.hash(data: Data(passphrase.utf8)))
    }

    /// Tries to sign in. Returns true on success.
    ///
    /// The same message is shown whether the username or the passphrase was
    /// wrong, so the screen doesn't reveal which usernames exist.
    @discardableResult
    func signIn(username: String, passphrase: String, accounts: [UserAccount]) -> Bool {
        let attempted = Self.hash(passphrase)
        let match = accounts.first {
            $0.username.caseInsensitiveCompare(username) == .orderedSame
                && $0.credentialHash == attempted
        }

        guard let match else {
            lastError = "Username or passphrase is incorrect."
            return false
        }

        currentUser = match
        lastError = nil
        return true
    }

    func signOut() {
        currentUser = nil
        lastError = nil
    }

    /// Called before any change to stored data.
    ///
    /// The views already hide admin screens from general users, but checking
    /// again here means the guarantee doesn't rely on the UI being right.
    func requireEditPermission() throws {
        guard isSignedIn else { throw AccessError.notSignedIn }
        guard role.canEditRecords else { throw AccessError.insufficientPrivileges }
    }
}

/// Errors raised when someone tries to do something their role doesn't allow.
enum AccessError: LocalizedError {
    case notSignedIn
    case insufficientPrivileges

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            "You need to sign in first."
        case .insufficientPrivileges:
            "Only an administrator can change student records."
        }
    }
}
