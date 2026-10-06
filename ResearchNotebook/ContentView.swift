import SwiftData
import SwiftUI

struct ContentView: View {
  @Query private var projects: [Project]
  @Query private var tags: [Tag]
  @State private var uiState = NotebookUIState()
  @State private var columnVisibility: NavigationSplitViewVisibility = .all
  @State private var editedProject: Project?

  private var selectedProject: Project? {
    projects.first { $0.id == uiState.selectedProjectID }
  }

  private var selectedNote: Note? {
    guard let selectedProject else { return nil }
    return matchingNotes(
      in: selectedProject, searchText: uiState.searchText, tagID: uiState.selectedTagID
    )
    .first { $0.id == uiState.selectedNoteID }
  }

  private var visibleNoteIDs: [UUID] {
    guard let selectedProject else { return [] }
    return matchingNotes(
      in: selectedProject, searchText: uiState.searchText, tagID: uiState.selectedTagID
    )
    .map(\.id)
  }

  private var selectedTagName: String {
    tags.first { $0.id == uiState.selectedTagID }?.name ?? "すべてのタグ"
  }

  private var tagFilterMenu: some View {
    Menu {
      Button("すべてのタグ") { uiState.selectedTagID = nil }
      ForEach(tags.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }) {
        tag in
        Button(tag.name) {
          uiState.selectedTagID = tag.id
        }
        .accessibilityIdentifier("tag-filter-option-\(tag.id)")
      }
    } label: {
      Label(selectedTagName, systemImage: "tag")
    }
    .accessibilityLabel("タグで絞り込む、\(selectedTagName)")
    .accessibilityIdentifier("tag-filter")
  }

  private func notesColumn(for project: Project) -> some View {
    @Bindable var uiState = uiState
    return NoteListView(
      project: project,
      notes: matchingNotes(
        in: project, searchText: uiState.searchText, tagID: uiState.selectedTagID),
      uiState: uiState
    )
    .id(project.id)
    .navigationTitle(project.title)
    .searchable(text: $uiState.searchText, prompt: "このProject内のNoteを検索")
    .safeAreaInset(edge: .top) {
      HStack {
        tagFilterMenu
        Spacer()
      }
      .padding(.horizontal)
      .padding(.vertical, 4)
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button("Projectを編集") { editedProject = project }
          .accessibilityIdentifier("project-edit")
      }
    }
  }

  @ViewBuilder private var detailColumn: some View {
    if let note = selectedNote {
      NoteEditorView(note: note) { uiState.selectedNoteID = nil }
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

  @ViewBuilder private var contentColumn: some View {
    if let project = selectedProject {
      notesColumn(for: project)
    } else {
      ContentUnavailableView(
        "Projectを選択", systemImage: "folder", description: Text("Projectを選択すると、所属するNoteを表示します。")
      )
      .navigationTitle("Notes")
    }
  }

  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      ProjectSidebarView(
        projects: projects, uiState: uiState)
    } content: {
      contentColumn
    } detail: {
      detailColumn
    }
    .navigationSplitViewStyle(.balanced)
    .onChange(of: uiState.selectedProjectID) { _, _ in
      uiState.reconcileSelection(visibleNoteIDs: Set(visibleNoteIDs))
    }
    .onChange(of: visibleNoteIDs) { _, _ in
      uiState.reconcileSelection(visibleNoteIDs: Set(visibleNoteIDs))
    }
    .onChange(of: uiState.selectedNoteID) { _, noteID in
      columnVisibility = noteID == nil ? .all : .doubleColumn
    }
    .sheet(item: $editedProject) { project in
      ProjectFormView(project: project) {
        uiState.selectedProjectID = nil
        uiState.selectedNoteID = nil
      }
    }
  }
}
