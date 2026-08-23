import SwiftUI
import SwiftData

/// The signed-in app: a sidebar of sections with the chosen one alongside.
struct MainView: View {
    @Environment(SessionStore.self) private var session

    @State private var section: Section? = MainView.initialSection

    /// Normally the dashboard. In debug builds the screenshot tooling can open
    /// a particular section with `-UniTrackDemoSection students`.
    private static var initialSection: Section {
        #if DEBUG
        if let raw = UserDefaults.standard.string(forKey: "UniTrackDemoSection"),
           let requested = Section(rawValue: raw) {
            return requested
        }
        #endif
        return .dashboard
    }

    /// Top level areas of the app. Accounts only exists for administrators.
    enum Section: String, CaseIterable, Identifiable, Hashable {
        case dashboard
        case students
        case accounts

        var id: String { rawValue }

        var title: String {
            switch self {
            case .dashboard: "Dashboard"
            case .students: "Students"
            case .accounts: "Accounts"
            }
        }

        var systemImage: String {
            switch self {
            case .dashboard: "chart.pie.fill"
            case .students: "person.2.fill"
            case .accounts: "key.fill"
            }
        }
    }

    /// Sections this user can reach. Admin-only areas are left out entirely
    /// rather than shown disabled.
    private var availableSections: [Section] {
        session.canManageAccounts ? Section.allCases : [.dashboard, .students]
    }

    /// A general user only ever reaches their own record, so the section reads
    /// "My Record" rather than "Students".
    private func title(for item: Section) -> String {
        if item == .students && session.seesOwnRecordOnly { return "My Record" }
        return item.title
    }

    var body: some View {
        NavigationSplitView {
            List(availableSections, selection: $section) { item in
                Label(title(for: item), systemImage: item.systemImage)
                    .tag(item)
                    .padding(.vertical, 2)
            }
            .navigationSplitViewColumnWidth(min: 178, ideal: 196, max: 240)
            .safeAreaInset(edge: .bottom) {
                signedInFooter
            }
        } detail: {
            switch section {
            case .dashboard: DashboardView()
            case .students: StudentsScreen()
            case .accounts: AccountsView()
            case nil: DashboardView()
            }
        }
    }

    /// Who's signed in, and the way out. Sits at the foot of the sidebar the way
    /// most macOS apps put account controls.
    private var signedInFooter: some View {
        HStack(spacing: 9) {
            Image(systemName: session.canEditRecords ? "key.fill" : "eye.fill")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 0) {
                Text(session.currentUser?.displayName ?? "Signed in")
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                Text(session.role.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Button {
                session.signOut()
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Sign out")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.bar)
    }
}
