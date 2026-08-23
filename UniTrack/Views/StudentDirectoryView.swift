import SwiftUI
import SwiftData

/// The main screen: a searchable list of students on the left, the selected
/// student's record on the right.
struct StudentDirectoryView: View {
    @Environment(SessionStore.self) private var session
    @Query(sort: \Student.familyName) private var students: [Student]

    @State private var selection: Student?
    @State private var searchText = ""

    /// Students matching the search box. Matching on name or ID because staff
    /// tend to search by whichever they have to hand.
    private var filtered: [Student] {
        guard !searchText.isEmpty else { return students }
        return students.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText)
                || $0.studentID.contains(searchText)
        }
    }

    var body: some View {
        NavigationSplitView {
            List(filtered, id: \.persistentModelID, selection: $selection) { student in
                NavigationLink(value: student) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(student.sortableName)
                            .font(.body)
                        Text(student.studentID)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 260)
            .searchable(text: $searchText, prompt: "Name or student ID")
        } detail: {
            if let selection {
                StudentDetailView(student: selection)
            } else {
                ContentUnavailableView("No Student Selected",
                                       systemImage: "person.crop.circle",
                                       description: Text("Pick a student from the list to see their record."))
            }
        }
        .navigationTitle("Students")
        .toolbar {
            ToolbarItem(placement: .status) {
                // Showing the role makes the access level obvious at a glance,
                // which matters because it changes what the app will let you do.
                Label(session.role.displayName,
                      systemImage: session.canEditRecords ? "key.fill" : "eye")
                    .labelStyle(.titleAndIcon)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Sign Out", systemImage: "rectangle.portrait.and.arrow.right") {
                    session.signOut()
                }
                .buttonStyle(.glass)
            }
        }
    }
}
