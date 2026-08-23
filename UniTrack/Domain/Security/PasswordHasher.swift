import Foundation
import CommonCrypto

/// Turns a password into something safe to store, and checks one later.
///
/// Uses PBKDF2 with HMAC-SHA256 rather than a bare SHA-256. A plain hash is far
/// too quick — an attacker with the database can try billions of guesses a
/// second, and identical passwords produce identical hashes. PBKDF2 fixes both:
/// the per-user salt means two people with the same password get different
/// stored values, and the iteration count makes each guess deliberately slow.
enum PasswordHasher {

    /// Iteration count. OWASP's current guidance for PBKDF2-HMAC-SHA256 is at
    /// least 210,000, so that's what new accounts get. It's stored per account
    /// so the number can be raised later without locking anyone out.
    static let defaultIterations = 210_000

    static let saltByteCount = 16
    static let keyByteCount = 32

    enum HashingError: LocalizedError {
        case derivationFailed
        case passwordTooShort(minimum: Int)

        var errorDescription: String? {
            switch self {
            case .derivationFailed:
                "The password could not be processed."
            case .passwordTooShort(let minimum):
                "Password must be at least \(minimum) characters."
            }
        }
    }

    /// Shortest password we'll accept. Deliberately modest, but enough to stop
    /// single character logins.
    static let minimumLength = 8

    /// Makes a new random salt.
    static func makeSalt() -> Data {
        var bytes = [UInt8](repeating: 0, count: saltByteCount)
        // SecRandomCopyBytes is the system's cryptographic RNG. Falling back to
        // anything weaker would defeat the point, so a failure is fatal.
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        precondition(status == errSecSuccess, "Could not generate a random salt")
        return Data(bytes)
    }

    /// Derives the stored key for a password.
    static func derive(password: String,
                       salt: Data,
                       iterations: Int = defaultIterations) throws -> Data {
        let passwordBytes = Array(password.utf8)
        var derived = [UInt8](repeating: 0, count: keyByteCount)

        let status = salt.withUnsafeBytes { saltBuffer -> Int32 in
            CCKeyDerivationPBKDF(
                CCPBKDFAlgorithm(kCCPBKDF2),
                passwordBytes, passwordBytes.count,
                saltBuffer.bindMemory(to: UInt8.self).baseAddress, salt.count,
                CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                UInt32(iterations),
                &derived, derived.count
            )
        }

        guard status == kCCSuccess else { throw HashingError.derivationFailed }
        return Data(derived)
    }

    /// Builds the salt, iteration count and key for a brand new account.
    static func makeCredential(for password: String) throws -> (salt: Data, iterations: Int, hash: Data) {
        guard password.count >= minimumLength else {
            throw HashingError.passwordTooShort(minimum: minimumLength)
        }
        let salt = makeSalt()
        let iterations = defaultIterations
        let hash = try derive(password: password, salt: salt, iterations: iterations)
        return (salt, iterations, hash)
    }

    /// Checks a password against a stored credential.
    ///
    /// The comparison runs over every byte rather than stopping at the first
    /// difference, so how long it takes doesn't leak how much of the hash
    /// matched.
    static func verify(password: String,
                       salt: Data,
                       iterations: Int,
                       expected: Data) -> Bool {
        guard let candidate = try? derive(password: password, salt: salt, iterations: iterations),
              candidate.count == expected.count else { return false }

        var difference: UInt8 = 0
        for (a, b) in zip(candidate, expected) {
            difference |= a ^ b
        }
        return difference == 0
    }
}
