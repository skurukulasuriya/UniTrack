import SwiftUI
import SwiftData

/// One student's full record: personal details, course, enrolments, and the
/// calculated WAM and GPA.
struct StudentDetailView: View {
    @Environment(SessionStore.self) private var session
    let student: Student

    /// GPA scale being shown. ECU publishes the 4-point one, so that's the default.
    @State private var scale: GPAScale = .fourPoint

    private var courseWAM: Double? {
        WAMCalculator.wam(for: student.enrolments)
    }

    private var courseGPA: Double? {
        GPACalculator.gpa(for: student.enrolments, on: scale)
    }

    /// Newest results first, which is what people usually want to see.
    private var sortedEnrolments: [Enrolment] {
        student.enrolments.sorted {
            ($0.year, $0.progressionPeriod) > ($1.year, $1.progressionPeriod)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                identityHeader
                performanceCards
                enrolmentsTable
            }
            .padding(26)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(student.fullName)
        .navigationSubtitle(student.studentID)
    }

    private var identityHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(student.fullName)
                .font(.title.weight(.semibold))

            Grid(alignment: .leading, horizontalSpacing: 26, verticalSpacing: 6) {
                GridRow {
                    detailPair("Student ID", student.studentID)
                    detailPair("Status", student.status.displayName)
                }
                GridRow {
                    detailPair("Email", student.email)
                    detailPair("Date of Birth", student.dateOfBirth.formatted(date: .abbreviated, time: .omitted))
                }
                GridRow {
                    detailPair("Course", student.course.map { "\($0.code) — \($0.title)" } ?? "Not enrolled")
                        .gridCellColumns(2)
                }
            }
        }
    }

    private func detailPair(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
        }
    }

    /// WAM and GPA side by side. Grouped in one glass container so the two cards
    /// read as a pair.
    private var performanceCards: some View {
        GlassEffectContainer(spacing: 16) {
            HStack(spacing: 16) {
                metricCard(title: "Course WAM",
                           value: WAMCalculator.formatted(courseWAM),
                           caption: "Weighted by credit points")

                metricCard(title: "Course GPA",
                           value: GPACalculator.formatted(courseGPA, on: scale),
                           caption: "\(scale.displayName) scale")
                    .overlay(alignment: .bottomTrailing) {
                        Picker("Scale", selection: $scale) {
                            ForEach(GPAScale.allCases) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(width: 150)
                        .padding(12)
                    }
            }
        }
    }

    private func metricCard(title: String, value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 34, weight: .medium, design: .rounded))
                .monospacedDigit()
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    private var enrolmentsTable: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Enrolled Units")
                .font(.headline)

            Table(sortedEnrolments) {
                TableColumn("Unit") { enrolment in
                    Text(enrolment.unit?.code ?? "—")
                }
                .width(min: 84, ideal: 92)

                TableColumn("Title") { enrolment in
                    Text(enrolment.unit?.title ?? "—")
                }

                TableColumn("Period") { enrolment in
                    Text("\(enrolment.progressionPeriod) \(String(enrolment.year))")
                }
                .width(min: 118, ideal: 130)

                TableColumn("CP") { enrolment in
                    Text(enrolment.unit.map { String($0.creditPoints) } ?? "—")
                        .monospacedDigit()
                }
                .width(38)

                TableColumn("Mark") { enrolment in
                    Text(enrolment.mark.map(String.init) ?? "—")
                        .monospacedDigit()
                }
                .width(48)

                TableColumn("Grade") { enrolment in
                    Text(enrolment.grade.code)
                }
                .width(56)
            }
            .frame(minHeight: 220)

            if !session.canEditRecords {
                Label("Signed in as a general user, so this record is read only.",
                      systemImage: "lock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
