import Foundation

/// One completed unit's contribution to a Weighted Average Mark.
///
/// Kept as a plain value type rather than taking `Enrolment` directly so the
/// calculation can be checked against the university's published worked example
/// without needing a database.
struct WAMComponent: Equatable {
    let mark: Int
    let creditPoints: Int
    let weighting: Double

    init(mark: Int, creditPoints: Int, weighting: Double = 1.0) {
        self.mark = mark
        self.creditPoints = creditPoints
        self.weighting = weighting
    }
}

/// Works out a Weighted Average Mark the way ECU defines it.
///
///     WAM = sum(credit points x mark x weighting) / sum(credit points x weighting)
///
/// Failed and repeated units are included at their actual mark, and a withdrawn
/// fail counts as zero. Units without a mark out of 100 are left out entirely,
/// which is why `mark` is optional on `Enrolment` and gets filtered here.
enum WAMCalculator {

    /// Returns the WAM for the given components, or nil if there is nothing to
    /// average. Returning nil rather than 0 matters — a student with no marked
    /// units hasn't scored zero, they just don't have a WAM yet.
    static func wam(for components: [WAMComponent]) -> Double? {
        guard !components.isEmpty else { return nil }

        var weightedMarkTotal = 0.0
        var weightTotal = 0.0

        for component in components {
            let weight = Double(component.creditPoints) * component.weighting
            weightedMarkTotal += Double(component.mark) * weight
            weightTotal += weight
        }

        // Guard against a divide by zero if every unit somehow had no credit points.
        guard weightTotal > 0 else { return nil }
        return weightedMarkTotal / weightTotal
    }

    /// Pulls the usable components out of a set of enrolments and works out the WAM.
    ///
    /// Anything the policy excludes is dropped here: results with no numeric mark,
    /// and anything flagged as not counting (prior learning, cross-institutional
    /// study, ungraded passes).
    static func wam(for enrolments: [Enrolment]) -> Double? {
        let components = enrolments.compactMap { enrolment -> WAMComponent? in
            guard enrolment.countsTowardCalculations,
                  let mark = enrolment.mark,
                  let unit = enrolment.unit else { return nil }
            return WAMComponent(mark: mark,
                                creditPoints: unit.creditPoints,
                                weighting: unit.wamWeighting)
        }
        return wam(for: components)
    }

    /// WAM limited to one study period, which ECU calls the Progression Period WAM.
    static func periodWAM(for enrolments: [Enrolment],
                          year: Int,
                          progressionPeriod: String) -> Double? {
        let inPeriod = enrolments.filter {
            $0.year == year && $0.progressionPeriod == progressionPeriod
        }
        return wam(for: inPeriod)
    }

    /// Formats a WAM the way it appears on a transcript, to two decimal places.
    static func formatted(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.2f", value)
    }
}
