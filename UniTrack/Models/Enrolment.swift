import Foundation
import SwiftData

/// One student's attempt at one unit in a given study period.
///
/// This stores both a numeric mark and a grade on purpose. WAM is worked out
/// from the mark and GPA from the grade value, and for conceded or
/// supplementary passes you can't get one from the other.
@Model
final class Enrolment {
    var year: Int
    /// The study period, e.g. "Semester 2".
    var progressionPeriod: String
    /// Mark out of 100. Optional because units graded as ungraded pass or fail
    /// (UP / UF) don't have one.
    var mark: Int?
    var gradeRaw: String
    /// False for results PL294 excludes, such as ungraded passes, credit for
    /// prior learning, and cross-institutional study.
    var countsTowardCalculations: Bool

    var student: Student?
    var unit: Unit?

    /// Stored as a raw string so SwiftData can persist it, exposed as the enum.
    var grade: Grade {
        get { Grade(rawValue: gradeRaw) ?? .fail }
        set { gradeRaw = newValue.rawValue }
    }

    init(year: Int,
         progressionPeriod: String,
         mark: Int?,
         grade: Grade,
         countsTowardCalculations: Bool = true) {
        self.year = year
        self.progressionPeriod = progressionPeriod
        self.mark = mark
        self.gradeRaw = grade.rawValue
        self.countsTowardCalculations = countsTowardCalculations
    }
}
