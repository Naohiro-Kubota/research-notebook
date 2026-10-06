import SwiftData
import SwiftUI

func matchingNotes(in project: Project, searchText: String, tagID: UUID? = nil) -> [Note] {
  let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
  return project.notes.filter {
    (tagID == nil || $0.tags.contains { $0.id == tagID })
      && (query.isEmpty || $0.title.localizedCaseInsensitiveContains(query)
        || $0.body.localizedCaseInsensitiveContains(query))
  }
}

struct NoteListView: View {
  let project: Project
  let notes: [Note]
  @Bindable var uiState: NotebookUIState
  @Query private var webResources: [WebResource]
  @Environment(\.modelContext) private var modelContext
  @State private var showsCreation = false
  @State private var newTitle = ""
  @State private var newBody = ""
  @State private var saveFailed = false

  private var projectResources: [WebResource] {
    webResources.filter { $0.project?.id == project.id }
  }

  var body: some View {
    List(selection: $uiState.selectedNoteID) {
      Section("Notes") {
        ForEach(notes) { note in
          NavigationLink(value: note.id) {
            Text(note.title)
          }
          .accessibilityIdentifier("note-row-\(note.id.uuidString)")
          .accessibilityAddTraits(uiState.selectedNoteID == note.id ? .isSelected : [])
        }
      }
      if !projectResources.isEmpty {
        Section("Web Resources") {
          ForEach(
            projectResources.sorted {
              $0.title.localizedStandardCompare($1.title) == .orderedAscending
            }
          ) { resource in
            Link(destination: resource.url) {
              VStack(alignment: .leading) {
                Text(resource.title)
                Text(resource.doi)
                  .font(.caption)
              }
            }
            .accessibilityLabel("出典を開く、\(resource.title)、DOI \(resource.doi)")
            .accessibilityValue(resource.url.absoluteString)
            .accessibilityIdentifier("web-resource-link")
          }
        }
      }
    }
    .overlay {
      if project.notes.isEmpty && projectResources.isEmpty {
        ContentUnavailableView {
          Label("Noteがありません", systemImage: "note.text")
            .accessibilityIdentifier("note-empty")
        } description: {
          Text("追加ボタンからNoteを作成しましょう。")
        }
      } else if notes.isEmpty && projectResources.isEmpty {
        ContentUnavailableView {
          Label("条件に一致するNoteがありません", systemImage: "magnifyingglass")
            .accessibilityIdentifier("note-search-empty")
        } description: {
          Text("このProject内に検索とタグの条件に一致するNoteはありません。")
        }
      }
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          newTitle = ""
          newBody = ""
          showsCreation = true
        } label: {
          Label("Noteを追加", systemImage: "plus")
        }
        .accessibilityIdentifier("note-add")
        .keyboardShortcut("n", modifiers: .command)
      }
    }
    .sheet(isPresented: $showsCreation) {
      NavigationStack {
        Form {
          Section("タイトル（必須）") {
            TextField("Noteのタイトル", text: $newTitle)
              .accessibilityIdentifier("note-title-input")
          }
          Section("本文") {
            TextEditor(text: $newBody)
              .frame(minHeight: 160)
              .accessibilityLabel("Noteの本文")
              .accessibilityIdentifier("note-body-input")
          }
        }
        .navigationTitle("Noteを作成")
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("キャンセル") { showsCreation = false }
          }
          ToolbarItem(placement: .confirmationAction) {
            Button("作成") {
              let note = Note(project: project, title: newTitle, body: newBody)
              modelContext.insert(note)
              if saveChanges(modelContext) {
                uiState.selectedNoteID = note.id
                showsCreation = false
              } else {
                modelContext.delete(note)
                saveFailed = true
              }
            }
            .disabled(!isValidTitle(newTitle))
            .accessibilityIdentifier("note-create")
          }
        }
        .alert("変更を保存できませんでした", isPresented: $saveFailed) {
          Button("OK") {}
        }
      }
    }
  }
}
