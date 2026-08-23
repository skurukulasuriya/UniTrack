import Foundation

/// Figures shown on the dashboard.
///
/// Kept apart from the views so the numbers can be worked out and checked
/// without involving SwiftUI.
enum Analytics {

    /// One bar on the grade distribution chart.
    struct GradeCount: Identifiable {
        var id: String { grade.rawValue }
        let grade: Grade
        let count: Int
    }

    /// One point on the WAM comparison chart.
    struct StudentWAM: Identifiable {
        var id: String { studentID }
        let studentID: String
        let name: String
        let wam: Double
    }

    /// Enrolments grouped by the period they were taken in.
    struct PeriodLoad: Identifiable {
        var id: String { label }
        let label: String
        let enrolments: Int
        let averageMark: Double?
    }

    /// Average mark for one unit across every student who took it.
    struct UnitPerformance: Identifiable {
        var id: String { code }
        let code: String
        let title: String
        let averageMark: Double
        let cohort: Int
    }

    // MARK: - Cohort level

    /// How many students sit in each enrolment status.
    static func statusBreakdown(_ students: [Student]) -> [(status: EnrolmentStatus, count: Int)] {
        EnrolmentStatus.allCases.map { status in
            (status, students.filter { $0.status == status }.count)
        }
    }

    /// Grade distribution across every enrolment that counts.
    static func gradeDistribution(_ students: [Student]) -> [GradeCount] {
        let all = students.flatMap(\.enrolments).filter(\.countsTowardCalculations)
        return Grade.allCases.map { grade in
            GradeCount(grade: grade, count: all.filter { $0.grade == grade }.count)
        }
    }

    /// WAM for each student who has one, highest first.
    static func wamRanking(_ students: [Student]) -> [StudentWAM] {
        students.compactMap { student in
            guard let wam = WAMCalculator.wam(for: student.enrolments) else { return nil }
            return StudentWAM(studentID: student.studentID, name: student.sortableName, wam: wam)
        }
        .sorted { $0.wam > $1.wam }
    }

    /// Average WAM across the whole cohort.
    static func cohortAverageWAM(_ students: [Student]) -> Double? {
        let values = students.compactMap { WAMCalculator.wam(for: $0.enrolments) }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    /// Enrolment counts and average mark per study period, oldest first.
    static func loadByPeriod(_ students: [Student]) -> [PeriodLoad] {
        let all = students.flatMap(\.enrolments)
        let grouped = Dictionary(grouping: all) { "\($0.progressionPeriod) \($0.year)" }

        return grouped.map { label, entries in
            let marks = entries.compactMap(\.mark)
            let average = marks.isEmpty ? nil : Double(marks.reduce(0, +)) / Double(marks.count)
            return PeriodLoad(label: label, enrolments: entries.count, averageMark: average)
        }
        .sorted { $0.label < $1.label }
    }

    /// Average mark per unit, weakest first so problem units stand out.
    static func unitPerformance(_ students: [Student]) -> [UnitPerformance] {
        let all = students.flatMap(\.enrolments).filter { $0.mark != nil && $0.unit != nil }
        let grouped = Dictionary(grouping: all) { $0.unit!.code }

        return grouped.compactMap { code, entries -> UnitPerformance? in
            let marks = entries.compactMap(\.mark)
            guard !marks.isEmpty, let unit = entries.first?.unit else { return nil }
            let average = Double(marks.reduce(0, +)) / Double(marks.count)
            return UnitPerformance(code: code,
                                   title: unit.title,
                                   averageMark: average,
                                   cohort: marks.count)
        }
        .sorted { $0.averageMark < $1.averageMark }
    }

    // MARK: - Single student

    /// A student's marks over time, for their own progress chart.
    static func markTrend(for student: Student) -> [PeriodLoad] {
        loadByPeriod([student])
    }

    /// Pass rate across counted enrolments, as a fraction between 0 and 1.
    static func passRate(_ students: [Student]) -> Double? {
        let counted = students.flatMap(\.enrolments).filter(\.countsTowardCalculations)
        guard !counted.isEmpty else { return nil }
        let passed = counted.filter { $0.grade != .fail && $0.grade != .withdrawnFail }
        return Double(passed.count) / Double(counted.count)
    }
}
