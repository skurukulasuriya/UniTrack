import Foundation

/// Access level for someone signed in to UniTrack.
///
/// The assignment brief requires the system to support both admin and general
/// users, so this drives which screens get built and which edits are allowed.
enum Role: String, Codable, CaseIterable, Identifiable {
    /// Read-only access. Can browse students and view their records.
    case general
    /// Full access. Can edit enrolments and marks, and manage the catalogue.
    case admin

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .general: "General user"
        case .admin: "Administrator"
        }
    }

    /// Whether this role is allowed to change stored records.
    /// Checked in the domain layer as well as the views so the rule doesn't
    /// depend on the UI alone.
    var canEditRecords: Bool {
        self == .admin
    }
}
