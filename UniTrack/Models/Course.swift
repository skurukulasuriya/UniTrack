import Foundation
import SwiftData

/// A degree a student is enrolled in, e.g. Bachelor of Science (Computer Science).
@Model
final class Course {
    /// Course code as ECU publishes it, e.g. "Y63".
    @Attribute(.unique) var code: String
    var title: String
    /// "Undergraduate" or "Postgraduate".
    var level: String
    /// Credit points needed to complete the whole course.
    var totalCreditPoints: Int

    /// Units that make up this course. Deleting a course removes its units too,
    /// since a unit doesn't mean anything on its own here.
    @Relationship(deleteRule: .cascade, inverse: \Unit.course)
    var units: [Unit] = []

    /// Students enrolled in the course. Deleting a course shouldn't delete the
    /// students, so this uses the default nullify rule.
    @Relationship(inverse: \Student.course)
    var students: [Student] = []

    init(code: String, title: String, level: String = "Undergraduate", totalCreditPoints: Int) {
        self.code = code
        self.title = title
        self.level = level
        self.totalCreditPoints = totalCreditPoints
    }
}
