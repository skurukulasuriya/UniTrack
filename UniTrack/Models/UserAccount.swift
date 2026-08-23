import Foundation
import SwiftData

/// A login for the system, holding the role that decides what the user can do.
///
/// Only a hash of the passphrase is stored — never the passphrase itself.
@Model
final class UserAccount {
    @Attribute(.unique) var username: String
    var displayName: String
    var roleRaw: String
    /// SHA-256 of the passphrase. Fine for a demonstration app, though a real
    /// system would want a slow hash like PBKDF2 or Argon2 with a per-user salt.
    var credentialHash: Data

    var role: Role {
        get { Role(rawValue: roleRaw) ?? .general }
        set { roleRaw = newValue.rawValue }
    }

    init(username: String, displayName: String, role: Role, credentialHash: Data) {
        self.username = username
        self.displayName = displayName
        self.roleRaw = role.rawValue
        self.credentialHash = credentialHash
    }
}
