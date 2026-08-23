import SwiftUI
import SwiftData

/// Sign in screen. Which role you sign in as decides what the rest of the app
/// will let you do.
struct SignInView: View {
    @Environment(SessionStore.self) private var session
    @Query private var accounts: [UserAccount]

    @State private var username = ""
    @State private var passphrase = ""
    @FocusState private var focusedField: Field?

    private enum Field { case username, passphrase }

    var body: some View {
        // A glass container lets the two glass surfaces blend into each other
        // instead of each being drawn separately.
        GlassEffectContainer(spacing: 20) {
            VStack(spacing: 24) {
                header

                VStack(spacing: 14) {
                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .username)
                        .onSubmit { focusedField = .passphrase }

                    SecureField("Passphrase", text: $passphrase)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .passphrase)
                        .onSubmit(attemptSignIn)

                    if let error = session.lastError {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button("Sign In", action: attemptSignIn)
                        .buttonStyle(.glassProminent)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                        .disabled(username.isEmpty || passphrase.isEmpty)
                }
                .frame(width: 320)
                .padding(24)
                .glassEffect(.regular, in: .rect(cornerRadius: 20))
            }
            .padding(40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
        .onAppear { focusedField = .username }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Image(systemName: "graduationcap")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.secondary)
            Text("UniTrack")
                .font(.largeTitle.weight(.semibold))
            Text("ECU Student Record System")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func attemptSignIn() {
        guard !username.isEmpty, !passphrase.isEmpty else { return }
        let signedIn = session.signIn(username: username,
                                      passphrase: passphrase,
                                      accounts: accounts)
        if signedIn {
            passphrase = ""
        }
    }
}
