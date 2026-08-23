// Checks the password hashing behaves the way it should.
import Foundation

print("=== PasswordHasher ===")

let password = "correct horse battery"
let cred = try! PasswordHasher.makeCredential(for: password)

print("salt bytes           :", cred.salt.count)
print("iterations           :", cred.iterations)
print("derived key bytes    :", cred.hash.count)
print("hash is not the password:",
      !cred.hash.elementsEqual(Array(password.utf8)))

// Right password verifies
print("correct password ->", PasswordHasher.verify(password: password, salt: cred.salt,
                                                   iterations: cred.iterations, expected: cred.hash))
// Wrong password rejected
print("wrong password   ->", PasswordHasher.verify(password: "wrong guess here", salt: cred.salt,
                                                   iterations: cred.iterations, expected: cred.hash))
// Near miss rejected
print("near miss        ->", PasswordHasher.verify(password: "correct horse batterY", salt: cred.salt,
                                                   iterations: cred.iterations, expected: cred.hash))

// Same password, two accounts -> different salts AND different stored hashes
let a = try! PasswordHasher.makeCredential(for: "identical-password")
let b = try! PasswordHasher.makeCredential(for: "identical-password")
print("\nsame password, different salts:", a.salt != b.salt)
print("same password, different hashes:", a.hash != b.hash)

// Too-short passwords rejected
do {
    _ = try PasswordHasher.makeCredential(for: "short")
    print("short password REJECTED: false")
} catch {
    print("short password REJECTED: true  (\(error.localizedDescription))")
}

// Cost check - a deliberately slow hash is the point
let started = Date()
_ = try! PasswordHasher.derive(password: password, salt: cred.salt, iterations: cred.iterations)
print(String(format: "\nsingle derivation took %.0f ms (slow on purpose)",
             Date().timeIntervalSince(started) * 1000))
