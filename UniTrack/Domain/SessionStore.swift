import Foundation
import SwiftData
import SwiftUI

/// Holds who is signed in and what they're allowed to do.
///
/// Every check on whether an action is permitted goes through here, so the rule
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

    /// Whether the current user may manage logins.
    var canManageAccounts: Bool { isSignedIn && role.canEditRecords }

    // MARK: - Signing in and out

    /// Tries to sign in. Returns true on success.
    ///
    /// The same message comes back whether the username or the password was
    /// wrong, so the screen doesn't reveal which usernames exist.
    @discardableResult
    func signIn(username: String, password: String, accounts: [UserAccount]) -> Bool {
        let trimmed = username.trimmingCharacters(in: .whitespaces)
        let match = accounts.first {
            $0.username.caseInsensitiveCompare(trimmed) == .orderedSame
        }

        guard let match, match.matches(password: password) else {
            lastError = "Username or password is incorrect."
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

    // MARK: - Access control

    /// Called before any change to stored data.
    ///
    /// The views already hide admin screens from general users, but checking
    /// again here means the guarantee doesn't rely on the UI being right.
    func requireEditPermission() throws {
        guard isSignedIn else { throw AccessError.notSignedIn }
        guard role.canEditRecords else { throw AccessError.insufficientPrivileges }
    }

    // MARK: - Managing accounts

    /// Creates a login. Only an administrator may do this, and administrators
    /// can create accounts of either role.
    ///
    /// The very first account is the exception — there's nobody to be signed in
    /// as yet, so `allowWithoutSession` covers first run setup.
    @discardableResult
    func createAccount(username: String,
                       displayName: String,
                       role newRole: Role,
                       password: String,
                       existing: [UserAccount],
                       context: ModelContext,
                       allowWithoutSession: Bool = false) throws -> UserAccount {
        if !allowWithoutSession {
            try requireEditPermission()
        }

        let trimmed = username.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { throw AccountError.usernameEmpty }
        guard !existing.contains(where: {
            $0.username.caseInsensitiveCompare(trimmed) == .orderedSame
        }) else { throw AccountError.usernameTaken(trimmed) }

        let account = try UserAccount(
            username: trimmed,
            displayName: displayName.isEmpty ? trimmed : displayName,
            role: newRole,
            password: password
        )
        context.insert(account)
        return account
    }

    /// Removes a login. Guards against an administrator deleting themselves or
    /// removing the last administrator, either of which would lock everyone out.
    func deleteAccount(_ account: UserAccount,
                       existing: [UserAccount],
                       context: ModelContext) throws {
        try requireEditPermission()

        guard account.persistentModelID != currentUser?.persistentModelID else {
            throw AccountError.cannotDeleteSelf
        }

        let remainingAdmins = existing.filter {
            $0.role == .admin && $0.persistentModelID != account.persistentModelID
        }
        guard !remainingAdmins.isEmpty else { throw AccountError.lastAdministrator }

        context.delete(account)
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
            "Only an administrator can make this change."
        }
    }
}

/// Problems with creating or removing a login.
enum AccountError: LocalizedError {
    case usernameEmpty
    case usernameTaken(String)
    case cannotDeleteSelf
    case lastAdministrator

    var errorDescription: String? {
        switch self {
        case .usernameEmpty:
            "Enter a username."
        case .usernameTaken(let name):
            "The username \"\(name)\" is already in use."
        case .cannotDeleteSelf:
            "You can't delete the account you're signed in with."
        case .lastAdministrator:
            "There has to be at least one administrator."
        }
    }
}
