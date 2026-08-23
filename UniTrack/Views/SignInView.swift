import SwiftUI
import SwiftData

/// Sign in screen. Which role you sign in as decides what the rest of the app
/// will let you do.
struct SignInView: View {
    @Environment(SessionStore.self) private var session
    @Query private var accounts: [UserAccount]

    @State private var username = ""
    @State private var password = ""
    @State private var isShaking = false
    @FocusState private var focusedField: Field?

    private enum Field { case username, password }

    private var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }

    var body: some View {
        ZStack {
            backdrop

            GlassEffectContainer(spacing: 22) {
                VStack(spacing: 20) {
                    branding
                    signInCard
                }
                .frame(width: 380)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { focusedField = .username }
    }

    /// Soft layered background so the glass has something to sit against.
    /// Without this the panel reads as a flat grey rectangle.
    private var backdrop: some View {
        ZStack {
            Rectangle().fill(.background)
            Circle()
                .fill(.tint.opacity(0.16))
                .blur(radius: 130)
                .frame(width: 460, height: 460)
                .offset(x: -170, y: -160)
            Circle()
                .fill(.tint.opacity(0.10))
                .blur(radius: 150)
                .frame(width: 520, height: 520)
                .offset(x: 190, y: 190)
        }
        .ignoresSafeArea()
    }

    private var branding: some View {
        VStack(spacing: 10) {
            UniversityLogo(height: 62)

            VStack(spacing: 3) {
                Text("UniTrack")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                Text("ECU Student Record System")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var signInCard: some View {
        VStack(spacing: 16) {
            LabelledField(title: "Username", systemImage: "person") {
                TextField("Enter your username", text: $username)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .username)
                    .onSubmit { focusedField = .password }
            }

            LabelledField(title: "Password", systemImage: "lock") {
                SecureField("Enter your password", text: $password)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .password)
                    .onSubmit(attemptSignIn)
            }

            if let error = session.lastError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .symbolRenderingMode(.hierarchical)
                    Text(error)
                    Spacer(minLength: 0)
                }
                .font(.caption)
                .foregroundStyle(.red)
                .transition(.opacity)
            }

            Button(action: attemptSignIn) {
                Text("Sign In")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .disabled(!canSubmit)
            .padding(.top, 2)
        }
        .padding(22)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
        // A small nudge on a failed attempt is clearer than only changing text.
        .offset(x: isShaking ? -7 : 0)
        .animation(.spring(response: 0.18, dampingFraction: 0.28), value: isShaking)
    }

    private func attemptSignIn() {
        guard canSubmit else { return }
        let signedIn = session.signIn(username: username,
                                      password: password,
                                      accounts: accounts)
        if signedIn {
            password = ""
        } else {
            password = ""
            focusedField = .password
            isShaking = true
            // Snap back so the shake can run again on the next failed attempt.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                isShaking = false
            }
        }
    }
}
