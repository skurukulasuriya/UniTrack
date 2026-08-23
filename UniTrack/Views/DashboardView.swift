import SwiftUI
import SwiftData
import Charts

/// Central dashboard. Both roles get the cohort overview and charts; an
/// administrator additionally sees per-unit performance and account figures.
struct DashboardView: View {
    @Environment(SessionStore.self) private var session
    @Query(sort: \Student.familyName) private var students: [Student]
    @Query private var accounts: [UserAccount]
    @Query private var units: [Unit]

    private var gradeCounts: [Analytics.GradeCount] {
        Analytics.gradeDistribution(students).filter { $0.count > 0 }
    }
    private var wamRanking: [Analytics.StudentWAM] { Analytics.wamRanking(students) }
    private var periods: [Analytics.PeriodLoad] { Analytics.loadByPeriod(students) }
    private var unitPerformance: [Analytics.UnitPerformance] { Analytics.unitPerformance(students) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                summaryTiles
                gradeDistributionCard
                wamComparisonCard
                periodTrendCard
                if session.canEditRecords {
                    unitPerformanceCard
                }
            }
            .padding(22)
            .frame(maxWidth: 1000, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(.background)
        .navigationTitle("Dashboard")
        .navigationSubtitle(session.canEditRecords ? "Administrator view" : "General view")
    }

    // MARK: - Summary

    private var summaryTiles: some View {
        GlassEffectContainer(spacing: 14) {
            HStack(spacing: 14) {
                MetricCard(title: "Students",
                           value: "\(students.count)",
                           caption: "\(students.filter { $0.status == .active }.count) active",
                           systemImage: "person.2.fill")

                MetricCard(title: "Cohort WAM",
                           value: WAMCalculator.formatted(Analytics.cohortAverageWAM(students)),
                           caption: "Mean across students",
                           systemImage: "chart.bar.fill")

                MetricCard(title: "Pass Rate",
                           value: Analytics.passRate(students).map {
                               String(format: "%.0f%%", $0 * 100)
                           } ?? "—",
                           caption: "Of counted enrolments",
                           systemImage: "checkmark.seal.fill")

                if session.canEditRecords {
                    MetricCard(title: "Accounts",
                               value: "\(accounts.count)",
                               caption: "\(accounts.filter { $0.role == .admin }.count) administrators",
                               systemImage: "key.fill")
                } else {
                    MetricCard(title: "Units",
                               value: "\(units.count)",
                               caption: "In the catalogue",
                               systemImage: "book.fill")
                }
            }
        }
    }

    // MARK: - Charts

    private var gradeDistributionCard: some View {
        SectionCard(title: "Grade Distribution", systemImage: "chart.bar.xaxis") {
            if gradeCounts.isEmpty {
                emptyChartNotice
            } else {
                Chart(gradeCounts) { entry in
                    BarMark(
                        x: .value("Grade", entry.grade.code),
                        y: .value("Enrolments", entry.count)
                    )
                    .foregroundStyle(.tint)
                    .cornerRadius(4)
                    .annotation(position: .top) {
                        Text("\(entry.count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 190)
            }
        }
    }

    private var wamComparisonCard: some View {
        SectionCard(title: "Weighted Average Mark by Student", systemImage: "chart.bar.horizontal.page") {
            if wamRanking.isEmpty {
                emptyChartNotice
            } else {
                Chart(wamRanking) { entry in
                    BarMark(
                        x: .value("WAM", entry.wam),
                        y: .value("Student", entry.name)
                    )
                    .foregroundStyle(.tint)
                    .cornerRadius(4)
                    .annotation(position: .trailing) {
                        Text(String(format: "%.2f", entry.wam))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if let average = Analytics.cohortAverageWAM(students) {
                        RuleMark(x: .value("Cohort average", average))
                            .foregroundStyle(.secondary)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            .annotation(position: .top, alignment: .leading) {
                                Text("Cohort average")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .chartXScale(domain: 0...100)
                .frame(height: CGFloat(wamRanking.count) * 38 + 40)
            }
        }
    }

    private var periodTrendCard: some View {
        SectionCard(title: "Average Mark by Study Period", systemImage: "chart.line.uptrend.xyaxis") {
            let withMarks = periods.filter { $0.averageMark != nil }
            if withMarks.isEmpty {
                emptyChartNotice
            } else {
                Chart(withMarks) { period in
                    LineMark(
                        x: .value("Period", period.label),
                        y: .value("Average mark", period.averageMark ?? 0)
                    )
                    .foregroundStyle(.tint)
                    .symbol(.circle)

                    AreaMark(
                        x: .value("Period", period.label),
                        y: .value("Average mark", period.averageMark ?? 0)
                    )
                    .foregroundStyle(.tint.opacity(0.12))
                }
                .chartYScale(domain: 0...100)
                .chartYAxis { AxisMarks(position: .leading) }
                .frame(height: 190)
            }
        }
    }

    private var unitPerformanceCard: some View {
        SectionCard(title: "Unit Performance", systemImage: "books.vertical.fill") {
            if unitPerformance.isEmpty {
                emptyChartNotice
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Text("Unit").frame(width: 80, alignment: .leading)
                        Text("Title").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Cohort").frame(width: 54, alignment: .trailing)
                        Text("Average").frame(width: 64, alignment: .trailing)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                    Divider().padding(.vertical, 3)

                    ForEach(unitPerformance) { unit in
                        HStack {
                            Text(unit.code)
                                .font(.callout.monospaced())
                                .frame(width: 80, alignment: .leading)
                            Text(unit.title)
                                .font(.callout)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(unit.cohort)")
                                .font(.callout)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                                .frame(width: 54, alignment: .trailing)
                            Text(String(format: "%.1f", unit.averageMark))
                                .font(.callout)
                                .monospacedDigit()
                                .frame(width: 64, alignment: .trailing)
                        }
                        .padding(.vertical, 5)

                        if unit.id != unitPerformance.last?.id {
                            Divider().opacity(0.4)
                        }
                    }

                    Text("Sorted by average mark, weakest first.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                }
            }
        }
    }

    private var emptyChartNotice: some View {
        Text("No results recorded yet.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 90)
    }
}
