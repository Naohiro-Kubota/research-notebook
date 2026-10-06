import SwiftData
import SwiftUI

struct ContentView: View {
  @Query private var projects: [Project]
  @State private var selectedProjectID: UUID?
  @State private var selectedNoteID: UUID?
  @State private var searchText = ""
  @State private var columnVisibility: NavigationSplitViewVisibility = .all
  @State private var editedProject: Project?

  private var selectedProject: Project? {
    projects.first { $0.id == selectedProjectID }
  }

  private var selectedNote: Note? {
    guard let selectedProject else { return nil }
    return matchingNotes(in: selectedProject, searchText: searchText)
      .first { $0.id == selectedNoteID }
  }

  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      ProjectSidebarView(
        projects: projects, selectedProjectID: $selectedProjectID,
        selectedNoteID: $selectedNoteID)
    } content: {
      if let project = selectedProject {
        NoteListView(
          project: project,
          notes: matchingNotes(in: project, searchText: searchText),
          selectedNoteID: $selectedNoteID
        )
        .id(project.id)
        .navigationTitle(project.title)
        .searchable(text: $searchText, prompt: "このProject内のNoteを検索")
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
        NoteEditorView(note: note) {
          selectedNoteID = nil
        }
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
    .onChange(of: searchText) { _, _ in
      if selectedNoteID != nil && selectedNote == nil {
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
