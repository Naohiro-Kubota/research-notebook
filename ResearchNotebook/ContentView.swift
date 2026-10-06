import SwiftData
import SwiftUI

struct ContentView: View {
  @Query private var projects: [Project]
  @Query private var tags: [Tag]
  @State private var selectedProjectID: UUID?
  @State private var selectedNoteID: UUID?
  @State private var searchText = ""
  @State private var selectedTagID: UUID?
  @State private var columnVisibility: NavigationSplitViewVisibility = .all
  @State private var editedProject: Project?

  private var selectedProject: Project? {
    projects.first { $0.id == selectedProjectID }
  }

  private var selectedNote: Note? {
    guard let selectedProject else { return nil }
    return matchingNotes(in: selectedProject, searchText: searchText, tagID: selectedTagID)
      .first { $0.id == selectedNoteID }
  }

  private var visibleNoteIDs: [UUID] {
    guard let selectedProject else { return [] }
    return matchingNotes(in: selectedProject, searchText: searchText, tagID: selectedTagID)
      .map(\.id)
  }

  private var selectedTagName: String {
    tags.first { $0.id == selectedTagID }?.name ?? "すべてのタグ"
  }

  private var tagFilterMenu: some View {
    Menu {
      Button("すべてのタグ") { selectedTagID = nil }
      ForEach(tags.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }) {
        tag in
        Button(tag.name) {
          selectedTagID = tag.id
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
    NoteListView(
      project: project,
      notes: matchingNotes(in: project, searchText: searchText, tagID: selectedTagID),
      selectedNoteID: $selectedNoteID
    )
    .id(project.id)
    .navigationTitle(project.title)
    .searchable(text: $searchText, prompt: "このProject内のNoteを検索")
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
      NoteEditorView(note: note) { selectedNoteID = nil }
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

  private func clearHiddenSelection() {
    if let selectedNoteID, !visibleNoteIDs.contains(selectedNoteID) {
      self.selectedNoteID = nil
    }
  }

  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      ProjectSidebarView(
        projects: projects, selectedProjectID: $selectedProjectID,
        selectedNoteID: $selectedNoteID)
    } content: {
      contentColumn
    } detail: {
      detailColumn
    }
    .navigationSplitViewStyle(.balanced)
    .onChange(of: selectedProjectID) { _, _ in clearHiddenSelection() }
    .onChange(of: visibleNoteIDs) { _, _ in clearHiddenSelection() }
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
