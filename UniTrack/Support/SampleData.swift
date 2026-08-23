import Foundation
import SwiftData

/// Seeds the academic records the first time the app runs.
///
/// The course and unit codes are the real ones ECU publishes for the Bachelor of
/// Computer Science, so the screens show something recognisable rather than
/// placeholder text. The students and their marks are invented.
///
/// Deliberately creates no logins. The first administrator is set up by whoever
/// runs the app, so there is no account here with a password sitting in the
/// source code.
enum SampleData {

    /// Small reproducible generator.
    ///
    /// Using `Int.random` would give different marks on every fresh install,
    /// which makes the dashboard impossible to compare between runs. A fixed
    /// seed keeps the sample cohort identical each time.
    private struct SeededGenerator: RandomNumberGenerator {
        private var state: UInt64
        init(seed: UInt64) { state = seed }

        mutating func next() -> UInt64 {
            // xorshift64*, small and good enough for picking sample marks.
            state ^= state >> 12
            state ^= state << 25
            state ^= state >> 27
            return state &* 2_685_821_657_736_338_717
        }
    }

    private static let givenNames = [
        "Amara", "Nadia", "Tharindu", "Ishara", "Dilhan", "Sanuli", "Ravindu",
        "Chamodi", "Kasun", "Hiruni", "Yasas", "Nethmi", "Pasindu", "Oshadi",
        "Lakmal", "Senuri", "Dinuka", "Tharushi", "Janith", "Malsha",
        "Ruwan", "Piumi", "Sahan", "Anjali", "Nuwan", "Dewmi", "Chathura", "Imasha",
    ]

    private static let familyNames = [
        "Fernando", "Perera", "Silva", "Jayawardena", "Bandara", "Wickramasinghe",
        "Gunasekara", "Rajapaksa", "Herath", "Dissanayake", "Weerasinghe",
        "Ekanayake", "Senanayake", "Abeywickrama", "Rathnayake", "Amarasinghe",
        "Karunaratne", "Wijesinghe", "Samaraweera", "Liyanage",
        "Kodikara", "Munasinghe", "Peiris", "Gamage", "Alwis", "Mendis",
        "Rodrigo", "Wanigasekara",
    ]

    /// Fills an empty store. Does nothing if there's already data, so restarting
    /// the app doesn't pile up duplicates.
    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        let existing = try? context.fetch(FetchDescriptor<Student>())
        guard existing?.isEmpty ?? true else { return }

        let course = Course(code: "U65",
                            title: "Bachelor of Computer Science",
                            level: "Undergraduate",
                            totalCreditPoints: 360)
        context.insert(course)

        let units = [
            Unit(code: "CSP1150", title: "Programming Principles", semesterOffered: "Semester 1"),
            Unit(code: "CSI1241", title: "Systems Analysis", semesterOffered: "Semester 1"),
            Unit(code: "ENS1161", title: "Computer Fundamentals", semesterOffered: "Semester 2"),
            Unit(code: "CSG1207", title: "Systems and Database Design", semesterOffered: "Semester 2"),
            Unit(code: "CSP2348", title: "Data Structures", semesterOffered: "Semester 1"),
            Unit(code: "CSP2104", title: "Object Oriented Programming with C++", semesterOffered: "Semester 2"),
            Unit(code: "CSI3344", title: "Distributed Systems", semesterOffered: "Semester 1"),
            Unit(code: "CSP3341", title: "Programming Languages and Paradigms", semesterOffered: "Semester 2"),
        ]
        for unit in units {
            unit.course = course
            context.insert(unit)
        }

        var generator = SeededGenerator(seed: 20_260_823)
        let orderedUnits = units.sorted { $0.code < $1.code }

        for index in 0..<28 {
            let given = givenNames[index % givenNames.count]
            let family = familyNames[index % familyNames.count]

            // Each student sits somewhere on a spread, so the cohort has strong
            // and struggling students rather than everyone clustering together.
            let ability = Int.random(in: 42...88, using: &generator)
            let unitsTaken = Int.random(in: 4...8, using: &generator)

            let student = Student(
                studentID: String(10_730_400 + index * 17),
                givenName: given,
                familyName: family,
                email: "\(given.lowercased()).\(family.lowercased())@our.ecu.edu.au",
                dateOfBirth: birthDate(offset: index),
                status: status(for: index)
            )
            student.course = course
            context.insert(student)

            for unitIndex in 0..<unitsTaken {
                let swing = Int.random(in: -12...12, using: &generator)
                var mark = max(0, min(100, ability + swing))

                // A small number of withdrawals, which count as a zero.
                let withdrew = Int.random(in: 0...24, using: &generator) == 0
                if withdrew { mark = 0 }

                let grade: Grade = withdrew ? .withdrawnFail : GradeMapper.grade(for: mark)

                let enrolment = Enrolment(
                    year: 2024 + (unitIndex / 4),
                    progressionPeriod: unitIndex.isMultiple(of: 2) ? "Semester 1" : "Semester 2",
                    mark: mark,
                    grade: grade
                )
                enrolment.student = student
                enrolment.unit = orderedUnits[unitIndex % orderedUnits.count]
                context.insert(enrolment)
            }
        }
    }

    /// Spreads birthdays across a few years so the column isn't all one date.
    private static func birthDate(offset: Int) -> Date {
        var components = DateComponents()
        components.year = 2001 + (offset % 5)
        components.month = (offset % 12) + 1
        components.day = (offset % 27) + 1
        return Calendar.current.date(from: components) ?? .now
    }

    /// Most students are active, with a few on leave or finished.
    private static func status(for index: Int) -> EnrolmentStatus {
        switch index % 11 {
        case 4: .onLeave
        case 9: .completed
        default: .active
        }
    }
}
