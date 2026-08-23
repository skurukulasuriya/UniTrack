import SwiftUI

/// Colours used across the app.
///
/// Teal is the accent, matching the table headers in the written report, and it
/// carries the controls and the single-series charts. Categorical charts use
/// distinct colours instead, because five shades of the same green are very
/// hard to tell apart in a pie slice or a legend.
extension Color {

    /// #27B198 — the project's accent colour.
    static let uniTrackAccent = Color(red: 0x27 / 255, green: 0xB1 / 255, blue: 0x98 / 255)

    // MARK: - Outcome colours

    /// Colours chosen so the meaning is obvious: green for a pass, red for a
    /// fail, grey for a withdrawal that was never really attempted.
    static let outcomePassed = uniTrackAccent
    static let outcomeFailed = Color(red: 0xD9 / 255, green: 0x4F / 255, blue: 0x4F / 255)
    static let outcomeWithdrawn = Color(red: 0x8A / 255, green: 0x8F / 255, blue: 0x98 / 255)

    // MARK: - Enrolment status

    static let statusActive = uniTrackAccent
    static let statusOnLeave = Color(red: 0xE0 / 255, green: 0xA1 / 255, blue: 0x3E / 255)
    static let statusCompleted = Color(red: 0x4A / 255, green: 0x8F / 255, blue: 0xD8 / 255)
    static let statusWithdrawn = outcomeWithdrawn

    // MARK: - Grade bands

    /// Warm at the bottom, teal at the top, so the shape of a distribution reads
    /// at a glance without having to check every axis label.
    static func gradeColour(_ grade: Grade) -> Color {
        switch grade {
        case .highDistinction:
            Color(red: 0x17 / 255, green: 0x8A / 255, blue: 0x76 / 255)
        case .distinction:
            uniTrackAccent
        case .credit:
            Color(red: 0x6F / 255, green: 0xCF / 255, blue: 0xBE / 255)
        case .pass:
            Color(red: 0xE0 / 255, green: 0xA1 / 255, blue: 0x3E / 255)
        case .passConceded, .passSupplementary:
            Color(red: 0xE8 / 255, green: 0xC0 / 255, blue: 0x6A / 255)
        case .fail:
            outcomeFailed
        case .withdrawnFail:
            outcomeWithdrawn
        }
    }

    static func statusColour(_ status: EnrolmentStatus) -> Color {
        switch status {
        case .active: statusActive
        case .onLeave: statusOnLeave
        case .completed: statusCompleted
        case .withdrawn: statusWithdrawn
        }
    }
}
