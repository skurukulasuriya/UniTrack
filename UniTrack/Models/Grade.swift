import Foundation

/// The grades ECU records against a completed unit.
///
/// Grade values come from the university's Weighted Average Mark and Grade Point
/// Average policy (PL294). The policy recognises both a 4-point and a 7-point
/// scale, so `gradeValue(on:)` takes the scale as a parameter rather than
/// assuming one.
enum Grade: String, Codable, CaseIterable, Identifiable {
    case highDistinction
    case distinction
    case credit
    case pass
    case passConceded
    case passSupplementary
    case fail
    case withdrawnFail

    var id: String { rawValue }

    /// Short code as it appears on a transcript.
    var code: String {
        switch self {
        case .highDistinction: "HD"
        case .distinction: "D"
        case .credit: "CR"
        case .pass: "P"
        case .passConceded: "PC"
        case .passSupplementary: "PS"
        case .fail: "F"
        case .withdrawnFail: "WF"
        }
    }

    var displayName: String {
        switch self {
        case .highDistinction: "High Distinction"
        case .distinction: "Distinction"
        case .credit: "Credit"
        case .pass: "Pass"
        case .passConceded: "Pass (Conceded)"
        case .passSupplementary: "Pass (Supplementary)"
        case .fail: "Fail"
        case .withdrawnFail: "Withdrawn Fail"
        }
    }

    /// Numeric value used when working out a GPA, taken from PL294 Table 2.
    ///
    /// The conceded and supplementary passes are the interesting ones: they are
    /// worth 1 on the 4-point scale but 4 on the 7-point scale, so the two
    /// scales are not just a multiple of each other.
    func gradeValue(on scale: GPAScale) -> Double {
        switch scale {
        case .fourPoint:
            switch self {
            case .highDistinction: 4.0
            case .distinction: 3.5
            case .credit: 3.0
            case .pass: 2.0
            case .passConceded, .passSupplementary: 1.0
            case .fail, .withdrawnFail: 0.0
            }
        case .sevenPoint:
            switch self {
            case .highDistinction: 7.0
            case .distinction: 6.0
            case .credit: 5.0
            case .pass, .passConceded, .passSupplementary: 4.0
            case .fail, .withdrawnFail: 0.0
            }
        }
    }
}

/// The two GPA scales ECU recognises.
///
/// Only the 4-point result is published on a transcript and in SIMO; the
/// 7-point figure is available on request.
enum GPAScale: String, Codable, CaseIterable, Identifiable {
    case fourPoint
    case sevenPoint

    var id: String { rawValue }

    /// Highest value the scale can produce, used when showing "3.72 / 4.0".
    var maximum: Double {
        switch self {
        case .fourPoint: 4.0
        case .sevenPoint: 7.0
        }
    }

    var displayName: String {
        switch self {
        case .fourPoint: "4-point"
        case .sevenPoint: "7-point"
        }
    }
}
