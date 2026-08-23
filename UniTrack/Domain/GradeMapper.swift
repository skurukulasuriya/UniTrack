import Foundation

/// Turns a numeric mark into the grade band it falls in.
///
/// These are the standard ECU bands. Conceded and supplementary passes aren't
/// produced here because they're an administrative decision rather than
/// something you can work out from the mark alone.
enum GradeMapper {

    static func grade(for mark: Int) -> Grade {
        switch mark {
        case 80...: .highDistinction
        case 70..<80: .distinction
        case 60..<70: .credit
        case 50..<60: .pass
        default: .fail
        }
    }

    /// Checks a stored mark and grade agree, for spotting data entry mistakes.
    /// Conceded and supplementary passes are skipped since they legitimately
    /// sit below the band their mark would suggest.
    static func isConsistent(mark: Int?, grade: Grade) -> Bool {
        guard let mark else { return true }
        switch grade {
        case .passConceded, .passSupplementary, .withdrawnFail:
            return true
        default:
            return self.grade(for: mark) == grade
        }
    }
}
