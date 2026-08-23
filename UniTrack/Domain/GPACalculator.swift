import Foundation

/// One completed unit's contribution to a Grade Point Average.
struct GPAComponent: Equatable {
    let grade: Grade
    let creditPoints: Int
}

/// Works out a Grade Point Average on either scale ECU recognises.
///
///     GPA = sum(credit points x grade value) / sum(credit points)
///
/// Unlike the WAM this runs off the grade rather than the mark, so a unit with a
/// grade but no numeric mark still counts.
enum GPACalculator {

    static func gpa(for components: [GPAComponent], on scale: GPAScale) -> Double? {
        guard !components.isEmpty else { return nil }

        var pointsTotal = 0.0
        var creditTotal = 0.0

        for component in components {
            let credit = Double(component.creditPoints)
            pointsTotal += component.grade.gradeValue(on: scale) * credit
            creditTotal += credit
        }

        guard creditTotal > 0 else { return nil }
        return pointsTotal / creditTotal
    }

    static func gpa(for enrolments: [Enrolment], on scale: GPAScale) -> Double? {
        let components = enrolments.compactMap { enrolment -> GPAComponent? in
            guard enrolment.countsTowardCalculations,
                  let unit = enrolment.unit else { return nil }
            return GPAComponent(grade: enrolment.grade, creditPoints: unit.creditPoints)
        }
        return gpa(for: components, on: scale)
    }

    /// Formats a GPA the way SIMO shows it, e.g. "3.729 / 4.0".
    static func formatted(_ value: Double?, on scale: GPAScale) -> String {
        guard let value else { return "—" }
        return String(format: "%.3f / %.1f", value, scale.maximum)
    }
}
