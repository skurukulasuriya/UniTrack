import Foundation
import SwiftData

/// A student record, which is what the whole application is built around.
@Model
final class Student {
    @Attribute(.unique) var studentID: String
    var givenName: String
    var familyName: String
    var email: String
    var dateOfBirth: Date
    var statusRaw: String

    var course: Course?

    @Relationship(deleteRule: .cascade, inverse: \Enrolment.student)
    var enrolments: [Enrolment] = []

    var status: EnrolmentStatus {
        get { EnrolmentStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    /// Family name first, which is how student lists are usually sorted.
    var sortableName: String {
        "\(familyName), \(givenName)"
    }

    var fullName: String {
        "\(givenName) \(familyName)"
    }

    init(studentID: String,
         givenName: String,
         familyName: String,
         email: String,
         dateOfBirth: Date,
         status: EnrolmentStatus = .active) {
        self.studentID = studentID
        self.givenName = givenName
        self.familyName = familyName
        self.email = email
        self.dateOfBirth = dateOfBirth
        self.statusRaw = status.rawValue
    }
}
