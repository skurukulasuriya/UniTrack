import SwiftUI
import SwiftData

/// Administrator screen for managing logins.
///
/// An administrator can create further administrators as well as general users,
/// which is what the assignment brief asks for. General users never reach this
/// screen — it isn't built for them at all.
struct AccountsView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.modelContext) private var context
    @Query(sort: \UserAccount.username) private var accounts: [UserAccount]

    @State private var isCreating = false
    @State private var pendingDeletion: UserAccount?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(.red)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassEffect(.regular, in: .rect(cornerRadius: 10))
                }

                summary
                accountList
            }
            .padding(22)
            .frame(maxWidth: 900, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(.background)
        .navigationTitle("Accounts")
        .navigationSubtitle("^[\(accounts.count) account](inflect: true)")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Account", systemImage: "person.badge.plus") {
                    isCreating = true
                }
                .buttonStyle(.glassProminent)
            }
        }
        .sheet(isPresented: $isCreating) {
            NewAccountSheet()
        }
        .confirmationDialog("Delete this account?",
                            isPresented: .constant(pendingDeletion != nil),
                            presenting: pendingDeletion) { account in
            Button("Delete \(account.username)", role: .destructive) {
                delete(account)
            }
            Button("Cancel", role: .cancel) { pendingDeletion = nil }
        } message: { account in
            Text("\(account.displayName) will no longer be able to sign in.")
        }
    }

    private var summary: some View {
        GlassEffectContainer(spacing: 14) {
            HStack(spacing: 14) {
                MetricCard(title: "Administrators",
                           value: "\(accounts.filter { $0.role == .admin }.count)",
                           caption: "Full access",
                           systemImage: "key.fill")
                MetricCard(title: "General Users",
                           value: "\(accounts.filter { $0.role == .general }.count)",
                           caption: "Read only",
                           systemImage: "eye.fill")
            }
        }
    }

    private var accountList: some View {
        SectionCard(title: "All Accounts", systemImage: "person.2.badge.gearshape") {
            VStack(spacing: 0) {
                ForEach(accounts) { account in
                    HStack(spacing: 12) {
                        Image(systemName: account.role == .admin ? "key.fill" : "eye.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 7) {
                                Text(account.displayName)
                                    .font(.body)
                                if account.persistentModelID == session.currentUser?.persistentModelID {
                                    StatusChip(text: "You", emphasised: true)
                                }
                            }
                            Text(account.username)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 0)

                        StatusChip(text: account.role.displayName)

                        Button {
                            errorMessage = nil
                            pendingDeletion = account
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                        .help("Delete this account")
                        .disabled(account.persistentModelID == session.currentUser?.persistentModelID)
                    }
                    .padding(.vertical, 8)

                    if account.id != accounts.last?.id {
                        Divider().opacity(0.4)
                    }
                }
            }
        }
    }

    private func delete(_ account: UserAccount) {
        do {
            try session.deleteAccount(account, existing: accounts, context: context)
            try context.save()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        pendingDeletion = nil
    }
}

/// Sheet for adding a login. The role picker is what lets an administrator
/// create either another administrator or an ordinary user.
struct NewAccountSheet: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var accounts: [UserAccount]

    @State private var displayName = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var role: Role = .general
    @State private var errorMessage: String?

    private var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty
            && password.count >= PasswordHasher.minimumLength
            && password == confirmation
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Account")
                .font(.title2.weight(.semibold))

            LabelledField(title: "Full Name", systemImage: "person") {
                TextField("e.g. Amara Fernando", text: $displayName)
                    .textFieldStyle(.plain)
            }

            LabelledField(title: "Username", systemImage: "at") {
                TextField("Choose a username", text: $username)
                    .textFieldStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 6) {
                Label("Access Level", systemImage: "lock.shield")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Picker("Access Level", selection: $role) {
                    ForEach(Role.allCases) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Text(role == .admin
                     ? "Can edit records and manage accounts."
                     : "Can view records but not change them.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            LabelledField(title: "Password", systemImage: "lock") {
                SecureField("At least \(PasswordHasher.minimumLength) characters", text: $password)
                    .textFieldStyle(.plain)
            }

            LabelledField(title: "Confirm Password", systemImage: "lock.rotation") {
                SecureField("Re-enter the password", text: $confirmation)
                    .textFieldStyle(.plain)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Create") { create() }
                    .buttonStyle(.glassProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSubmit)
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(width: 420)
    }

    private func create() {
        do {
            try session.createAccount(username: username,
                                      displayName: displayName,
                                      role: role,
                                      password: password,
                                      existing: accounts,
                                      context: context)
            try context.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
