import SwiftUI
import SwiftData

/// Shown the first time the app runs, when there are no logins yet.
///
/// The first administrator is created here rather than being seeded with a
/// known password, so no working credentials exist in the source code.
struct FirstRunSetupView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.modelContext) private var context
    @Query private var accounts: [UserAccount]

    @State private var displayName = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field { case displayName, username, password, confirmation }

    private var passwordsMatch: Bool {
        !password.isEmpty && password == confirmation
    }

    private var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty
            && password.count >= PasswordHasher.minimumLength
            && passwordsMatch
    }

    var body: some View {
        ZStack {
            Rectangle().fill(.background).ignoresSafeArea()

            GlassEffectContainer(spacing: 20) {
                VStack(spacing: 18) {
                    header
                    form
                }
                .frame(width: 400)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { focusedField = .displayName }
    }

    private var header: some View {
        VStack(spacing: 9) {
            Image(systemName: "person.badge.key.fill")
                .font(.system(size: 27, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .frame(width: 64, height: 64)
                .glassEffect(.regular, in: .circle)

            Text("Set Up UniTrack")
                .font(.system(size: 25, weight: .semibold, design: .rounded))
            Text("Create the first administrator account to get started.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var form: some View {
        VStack(spacing: 14) {
            LabelledField(title: "Full Name", systemImage: "person") {
                TextField("e.g. Records Administrator", text: $displayName)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .displayName)
                    .onSubmit { focusedField = .username }
            }

            LabelledField(title: "Username", systemImage: "at") {
                TextField("Choose a username", text: $username)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .username)
                    .onSubmit { focusedField = .password }
            }

            LabelledField(title: "Password", systemImage: "lock") {
                SecureField("At least \(PasswordHasher.minimumLength) characters", text: $password)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .password)
                    .onSubmit { focusedField = .confirmation }
            }

            LabelledField(title: "Confirm Password", systemImage: "lock.rotation") {
                SecureField("Re-enter the password", text: $confirmation)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .confirmation)
                    .onSubmit { if canSubmit { createAdministrator() } }
            }

            requirements

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: createAdministrator) {
                Text("Create Administrator")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .disabled(!canSubmit)
        }
        .padding(22)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }

    /// Live feedback so the button being disabled doesn't feel arbitrary.
    private var requirements: some View {
        VStack(alignment: .leading, spacing: 4) {
            requirementRow("At least \(PasswordHasher.minimumLength) characters",
                           met: password.count >= PasswordHasher.minimumLength)
            requirementRow("Both passwords match", met: passwordsMatch)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func requirementRow(_ text: String, met: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(met ? .green : .secondary)
            Text(text)
                .foregroundStyle(met ? .primary : .secondary)
        }
        .font(.caption)
    }

    private func createAdministrator() {
        do {
            let account = try session.createAccount(
                username: username,
                displayName: displayName,
                role: .admin,
                password: password,
                existing: accounts,
                context: context,
                // Nobody can be signed in yet, so the usual permission check
                // can't apply to the very first account.
                allowWithoutSession: true
            )
            try context.save()
            session.signIn(username: account.username, password: password, accounts: [account])
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

/// Shared labelled input used by the setup and sign in screens.
struct LabelledField<Content: View>: View {
    let title: String
    var systemImage: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            content
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .background(.quinary, in: .rect(cornerRadius: 9))
                .overlay {
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(.separator, lineWidth: 0.5)
                }
        }
    }
}
