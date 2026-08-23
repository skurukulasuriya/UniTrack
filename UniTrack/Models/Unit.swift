import Foundation
import SwiftData

/// A single unit of study, e.g. CSP3341 Programming Languages and Paradigms.
@Model
final class Unit {
    @Attribute(.unique) var code: String
    var title: String
    /// Credit points the unit is worth. This is the weighting used in the WAM
    /// and GPA calculations, so it matters that it's stored per unit.
    var creditPoints: Int
    /// PL294 lets a unit carry its own WAM weighting to weight different level
    /// units. The policy says it's 1.0 unless stated otherwise, so that's the
    /// default here rather than being assumed away.
    var wamWeighting: Double
    var semesterOffered: String

    var course: Course?

    @Relationship(deleteRule: .cascade, inverse: \Enrolment.unit)
    var enrolments: [Enrolment] = []

    init(code: String,
         title: String,
         creditPoints: Int = 15,
         wamWeighting: Double = 1.0,
         semesterOffered: String = "Semester 1") {
        self.code = code
        self.title = title
        self.creditPoints = creditPoints
        self.wamWeighting = wamWeighting
        self.semesterOffered = semesterOffered
    }
}
