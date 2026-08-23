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

    /// Credit points from units that actually count, which is what progress
    /// through the course is measured in.
    private var completedCreditPoints: Int {
        student.enrolments
            .filter { $0.countsTowardCalculations && $0.grade != .fail && $0.grade != .withdrawnFail }
            .compactMap { $0.unit?.creditPoints }
            .reduce(0, +)
    }

    /// Newest results first, which is what people usually want to see.
    private var sortedEnrolments: [Enrolment] {
        student.enrolments.sorted {
            ($0.year, $0.progressionPeriod) > ($1.year, $1.progressionPeriod)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                metrics
                detailsCard
                enrolmentsCard
                if !session.canEditRecords {
                    readOnlyNotice
                }
            }
            .padding(22)
            .frame(maxWidth: 900, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(.background)
        .navigationTitle(student.fullName)
        .navigationSubtitle(student.studentID)
    }

    private var header: some View {
        HStack(spacing: 14) {
            InitialsAvatar(givenName: student.givenName,
                           familyName: student.familyName,
                           size: 58)

            VStack(alignment: .leading, spacing: 5) {
                Text(student.fullName)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))

                HStack(spacing: 7) {
                    StatusChip(text: student.studentID, systemImage: "number")
                    StatusChip(text: student.status.displayName,
                               systemImage: statusIcon,
                               tint: Color.statusColour(student.status),
                               emphasised: student.status == .active)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var statusIcon: String {
        switch student.status {
        case .active: "checkmark.circle.fill"
        case .onLeave: "pause.circle.fill"
        case .completed: "graduationcap.fill"
        case .withdrawn: "xmark.circle.fill"
        }
    }

    /// The three headline figures, grouped so the glass reads as one surface.
    private var metrics: some View {
        GlassEffectContainer(spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                MetricCard(title: "Course WAM",
                           value: WAMCalculator.formatted(courseWAM),
                           caption: "Weighted by credit points",
                           systemImage: "chart.bar.fill")

                MetricCard(title: "Course GPA",
                           value: GPACalculator.formatted(courseGPA, on: scale),
                           caption: "\(scale.displayName) scale",
                           systemImage: "star.fill") {
                    Picker("Scale", selection: $scale) {
                        ForEach(GPAScale.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .controlSize(.small)
                }

                MetricCard(title: "Credit Points",
                           value: "\(completedCreditPoints)",
                           caption: "of \(student.course?.totalCreditPoints ?? 0) completed",
                           systemImage: "checkmark.seal.fill")
            }
            .frame(height: 150)
        }
    }

    private var detailsCard: some View {
        SectionCard(title: "Personal Details", systemImage: "person.text.rectangle") {
            Grid(alignment: .leading, horizontalSpacing: 30, verticalSpacing: 12) {
                GridRow {
                    labelled("Email", student.email)
                    labelled("Date of Birth",
                             student.dateOfBirth.formatted(date: .abbreviated, time: .omitted))
                }
                GridRow {
                    labelled("Course", student.course.map { "\($0.code) — \($0.title)" } ?? "Not enrolled")
                        .gridCellColumns(2)
                }
            }
        }
    }

    private func labelled(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var enrolmentsCard: some View {
        SectionCard(title: "Enrolled Units", systemImage: "list.bullet.rectangle") {
            VStack(spacing: 0) {
                columnHeadings

                Divider().padding(.vertical, 2)

                ForEach(sortedEnrolments, id: \.persistentModelID) { enrolment in
                    enrolmentRow(enrolment)
                    if enrolment.persistentModelID != sortedEnrolments.last?.persistentModelID {
                        Divider().opacity(0.4)
                    }
                }
            }
        }
    }

    private var columnHeadings: some View {
        HStack(spacing: 10) {
            Text("Unit").frame(width: 74, alignment: .leading)
            Text("Title").frame(maxWidth: .infinity, alignment: .leading)
            Text("Period").frame(width: 122, alignment: .leading)
            Text("CP").frame(width: 30, alignment: .trailing)
            Text("Mark").frame(width: 42, alignment: .trailing)
            Text("Grade").frame(width: 52, alignment: .center)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
    }

    private func enrolmentRow(_ enrolment: Enrolment) -> some View {
        HStack(spacing: 10) {
            Text(enrolment.unit?.code ?? "—")
                .font(.callout.monospaced())
                .frame(width: 74, alignment: .leading)

            Text(enrolment.unit?.title ?? "—")
                .font(.callout)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(enrolment.progressionPeriod) \(String(enrolment.year))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 122, alignment: .leading)

            Text(enrolment.unit.map { String($0.creditPoints) } ?? "—")
                .font(.callout)
                .monospacedDigit()
                .frame(width: 30, alignment: .trailing)

            Text(enrolment.mark.map(String.init) ?? "—")
                .font(.callout)
                .monospacedDigit()
                .frame(width: 42, alignment: .trailing)

            StatusChip(text: enrolment.grade.code,
                       tint: Color.gradeColour(enrolment.grade),
                       emphasised: enrolment.grade == .highDistinction)
                .frame(width: 52)
        }
        .padding(.vertical, 6)
    }

    private var readOnlyNotice: some View {
        Label("Signed in as a general user, so this record is read only.",
              systemImage: "lock.fill")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: 10))
    }
}
