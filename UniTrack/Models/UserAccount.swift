import Foundation
import SwiftData

/// A login for the system, holding the role that decides what the user can do.
///
/// No password is stored anywhere — only the salt, the iteration count, and the
/// key derived from them. There is no way to get the original password back out
/// of this, which is the point.
@Model
final class UserAccount {
    @Attribute(.unique) var username: String
    var displayName: String
    var roleRaw: String

    /// Random per-account salt, so two people with the same password still end
    /// up with completely different stored keys.
    var salt: Data
    /// Stored per account so the work factor can be raised later without
    /// locking out everyone who already has a login.
    var iterations: Int
    /// PBKDF2-HMAC-SHA256 output. Never the password itself.
    var credentialHash: Data

    var createdAt: Date

    var role: Role {
        get { Role(rawValue: roleRaw) ?? .general }
        set { roleRaw = newValue.rawValue }
    }

    init(username: String,
         displayName: String,
         role: Role,
         salt: Data,
         iterations: Int,
         credentialHash: Data,
         createdAt: Date = .now) {
        self.username = username
        self.displayName = displayName
        self.roleRaw = role.rawValue
        self.salt = salt
        self.iterations = iterations
        self.credentialHash = credentialHash
        self.createdAt = createdAt
    }

    /// Builds an account from a plain password, hashing it on the way in so the
    /// caller never has to handle the stored form itself.
    convenience init(username: String,
                     displayName: String,
                     role: Role,
                     password: String) throws {
        let credential = try PasswordHasher.makeCredential(for: password)
        self.init(username: username,
                  displayName: displayName,
                  role: role,
                  salt: credential.salt,
                  iterations: credential.iterations,
                  credentialHash: credential.hash)
    }

    /// Checks a password against what's stored.
    func matches(password: String) -> Bool {
        PasswordHasher.verify(password: password,
                              salt: salt,
                              iterations: iterations,
                              expected: credentialHash)
    }
}
