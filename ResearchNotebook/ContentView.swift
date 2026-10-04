import SwiftUI

struct ContentView: View {
  @State private var notebook = NotebookState()
  @State private var columnVisibility: NavigationSplitViewVisibility = .all
  @State private var editedProject: NotebookProject?

  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      ProjectSidebarView(notebook: $notebook)
    } content: {
      if let project = notebook.projects.first(where: { $0.id == notebook.selectedProjectID }) {
        ContentUnavailableView(
          "Noteがありません", systemImage: "note.text",
          description: Text("\(project.title)のNoteをここに表示します。")
        )
        .navigationTitle(project.title)
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            Button("Projectを編集") { editedProject = project }
              .accessibilityIdentifier("project-edit")
          }
        }
      } else {
        ContentUnavailableView(
          "Projectを選択", systemImage: "folder", description: Text("Projectを選択すると、所属するNoteを表示します。")
        )
        .navigationTitle("Notes")
      }
    } detail: {
      ContentUnavailableView(
        "Noteを選択", systemImage: "square.and.pencil", description: Text("Noteを選択すると、タイトルと本文を編集できます。")
      )
      .navigationTitle("Note")
    }
    .navigationSplitViewStyle(.balanced)
    .sheet(item: $editedProject) { project in
      ProjectFormView(notebook: $notebook, projectID: project.id)
    }
  }
}
