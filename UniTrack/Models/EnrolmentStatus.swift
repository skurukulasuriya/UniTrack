import Foundation

/// Where a student currently sits in their course.
enum EnrolmentStatus: String, Codable, CaseIterable, Identifiable {
    case active
    case onLeave
    case completed
    case withdrawn

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .active: "Active"
        case .onLeave: "On leave"
        case .completed: "Completed"
        case .withdrawn: "Withdrawn"
        }
    }
}
