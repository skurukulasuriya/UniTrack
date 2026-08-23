import Foundation
import SwiftData

/// Seeds the academic records the first time the app runs.
///
/// The course and unit codes are the real ones ECU publishes for the Bachelor of
/// Computer Science, so the screens show something recognisable rather than
/// placeholder text. Marks and student details are made up.
///
/// Deliberately creates no logins. The first administrator is set up by whoever
/// runs the app, so there is no account here with a password sitting in the
/// source code.
enum SampleData {

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

        let students = [
            makeStudent(id: "10730928", given: "Sandanu", family: "Kurukulasuriya",
                        year: 2003, month: 4, day: 12, course: course, context: context,
                        results: [(0, 78, .distinction), (1, 71, .distinction), (2, 84, .highDistinction),
                                  (3, 66, .credit), (4, 73, .distinction), (5, 69, .credit),
                                  (6, 81, .highDistinction), (7, 76, .distinction)]),
            makeStudent(id: "10730511", given: "Amara", family: "Fernando",
                        year: 2002, month: 9, day: 3, course: course, context: context,
                        results: [(0, 62, .credit), (1, 55, .pass), (2, 47, .fail),
                                  (3, 68, .credit), (4, 59, .pass), (5, 71, .distinction)]),
            makeStudent(id: "10731044", given: "Nadia", family: "Perera",
                        year: 2004, month: 1, day: 27, course: course, context: context,
                        results: [(0, 91, .highDistinction), (1, 88, .highDistinction),
                                  (2, 79, .distinction), (3, 85, .highDistinction)]),
            makeStudent(id: "10729860", given: "Tharindu", family: "Silva",
                        year: 2001, month: 11, day: 8, course: course, context: context,
                        results: [(0, 45, .passConceded), (1, 52, .pass), (2, 0, .withdrawnFail),
                                  (3, 61, .credit), (4, 58, .pass)]),
        ]

        for student in students {
            student.course = course
        }
    }

    /// Builds one student and their results. The tuple is (unit index, mark, grade).
    @MainActor
    private static func makeStudent(id: String,
                                    given: String,
                                    family: String,
                                    year: Int, month: Int, day: Int,
                                    course: Course,
                                    context: ModelContext,
                                    results: [(Int, Int, Grade)]) -> Student {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        let dob = Calendar.current.date(from: components) ?? .now

        let student = Student(studentID: id,
                              givenName: given,
                              familyName: family,
                              email: "\(given.lowercased()).\(family.lowercased())@our.ecu.edu.au",
                              dateOfBirth: dob)
        context.insert(student)

        let units = course.units.sorted { $0.code < $1.code }
        for (index, mark, grade) in results where index < units.count {
            let enrolment = Enrolment(year: 2025 + (index / 4),
                                      progressionPeriod: index.isMultiple(of: 2) ? "Semester 1" : "Semester 2",
                                      mark: mark,
                                      grade: grade)
            enrolment.student = student
            enrolment.unit = units[index]
            context.insert(enrolment)
        }
        return student
    }
}
