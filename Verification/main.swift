// Verification harness: runs the real WAMCalculator/GPACalculator against the
// worked example ECU publishes, which resolves to a WAM of 58.43.
import Foundation

let example = [
    WAMComponent(mark: 75, creditPoints: 15),  // D
    WAMComponent(mark: 69, creditPoints: 30),  // CR
    WAMComponent(mark: 83, creditPoints: 15),  // HD
    WAMComponent(mark: 71, creditPoints: 15),  // D
    WAMComponent(mark: 42, creditPoints: 15),  // F  - fails still count
    WAMComponent(mark: 0,  creditPoints: 15),  // WF - counts as zero
]

let wam = WAMCalculator.wam(for: example)
print("WAM raw      :", wam.map { String($0) } ?? "nil")
print("WAM formatted:", WAMCalculator.formatted(wam))
print("ECU expects  : 58.43")
print(WAMCalculator.formatted(wam) == "58.43" ? "PASS" : "FAIL")

// Sanity checks on the edges
print("\nempty input  :", WAMCalculator.formatted(WAMCalculator.wam(for: [WAMComponent]())), "(expect em dash, not 0.00)")

// GPA both scales, using the same six units' grades
let gpaParts = [
    GPAComponent(grade: .distinction, creditPoints: 15),
    GPAComponent(grade: .credit, creditPoints: 30),
    GPAComponent(grade: .highDistinction, creditPoints: 15),
    GPAComponent(grade: .distinction, creditPoints: 15),
    GPAComponent(grade: .fail, creditPoints: 15),
    GPAComponent(grade: .withdrawnFail, creditPoints: 15),
]
print("GPA 4-point  :", GPACalculator.formatted(GPACalculator.gpa(for: gpaParts, on: .fourPoint), on: .fourPoint))
print("GPA 7-point  :", GPACalculator.formatted(GPACalculator.gpa(for: gpaParts, on: .sevenPoint), on: .sevenPoint))

// Grade banding
print("\nband checks:")
for m in [85, 74, 65, 52, 30] {
    print("  mark \(m) -> \(GradeMapper.grade(for: m).code)")
}
// A conceded pass sits below its band on purpose and must not be flagged
print("  conceded pass at 45 consistent?", GradeMapper.isConsistent(mark: 45, grade: .passConceded))
