import SwiftUI
import SwiftData

/// Students area: a searchable list beside the selected student's record.
struct StudentsScreen: View {
    @Query(sort: \Student.familyName) private var students: [Student]

    /// Selection is by identifier rather than the model itself, because a
    /// List's selection binding has to match the type of the row id.
    @State private var selectedID: PersistentIdentifier?
    @State private var searchText = ""

    private var filtered: [Student] {
        guard !searchText.isEmpty else { return students }
        return students.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText)
                || $0.studentID.contains(searchText)
        }
    }

    private var selectedStudent: Student? {
        guard let selectedID else { return nil }
        return students.first { $0.persistentModelID == selectedID }
    }

    var body: some View {
        HSplitView {
            list
                .frame(minWidth: 250, idealWidth: 285, maxWidth: 360)

            Group {
                if let selectedStudent {
                    StudentDetailView(student: selectedStudent)
                } else {
                    ContentUnavailableView {
                        Label("No Student Selected", systemImage: "person.crop.circle")
                    } description: {
                        Text("Pick a student from the list to see their record, WAM and GPA.")
                    }
                }
            }
            .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Students")
        .navigationSubtitle("^[\(students.count) student](inflect: true)")
    }

    private var list: some View {
        VStack(spacing: 0) {
            // Rows are plain content, not NavigationLinks. A link would handle
            // the click itself and the selection would never update.
            List(filtered, id: \.persistentModelID, selection: $selectedID) { student in
                HStack(spacing: 10) {
                    InitialsAvatar(givenName: student.givenName, familyName: student.familyName)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(student.sortableName)
                            .font(.body)
                            .lineLimit(1)
                        HStack(spacing: 5) {
                            Text(student.studentID).monospacedDigit()
                            Text("·")
                            Text(student.status.displayName)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    }
                }
                .padding(.vertical, 3)
            }
            .searchable(text: $searchText, prompt: "Name or student ID")
        }
    }
}
