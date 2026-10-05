import SwiftData
import SwiftUI

struct ContentView: View {
  @Query private var projects: [Project]
  @State private var selectedProjectID: UUID?
  @State private var selectedNoteID: UUID?
  @State private var columnVisibility: NavigationSplitViewVisibility = .all
  @State private var editedProject: Project?

  private var selectedProject: Project? {
    projects.first { $0.id == selectedProjectID }
  }

  private var selectedNote: Note? {
    selectedProject?.notes.first { $0.id == selectedNoteID }
  }

  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      ProjectSidebarView(
        projects: projects, selectedProjectID: $selectedProjectID,
        selectedNoteID: $selectedNoteID)
    } content: {
      if let project = selectedProject {
        NoteListView(project: project, selectedNoteID: $selectedNoteID)
          .id(project.id)
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
      if let note = selectedNote {
        NoteEditorView(note: note)
          .id(note.id)
      } else {
        ContentUnavailableView {
          Label("Noteを選択", systemImage: "square.and.pencil")
            .accessibilityIdentifier("note-selection-empty")
        } description: {
          Text("Noteを選択すると、タイトルと本文を編集できます。")
        }
        .navigationTitle("Note")
      }
    }
    .navigationSplitViewStyle(.balanced)
    .onChange(of: selectedProjectID) { _, projectID in
      if projects.first(where: { $0.id == projectID })?.notes.contains(where: {
        $0.id == selectedNoteID
      }) != true {
        selectedNoteID = nil
      }
    }
    .onChange(of: selectedNoteID) { _, noteID in
      columnVisibility = noteID == nil ? .all : .doubleColumn
    }
    .sheet(item: $editedProject) { project in
      ProjectFormView(project: project) {
        selectedProjectID = nil
        selectedNoteID = nil
      }
    }
  }
}
