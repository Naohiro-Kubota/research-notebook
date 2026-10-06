import SwiftData
import SwiftUI

func matchingNotes(in project: Project, searchText: String) -> [Note] {
  let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
  guard !query.isEmpty else { return project.notes }
  return project.notes.filter {
    $0.title.localizedCaseInsensitiveContains(query)
      || $0.body.localizedCaseInsensitiveContains(query)
  }
}

struct NoteListView: View {
  let project: Project
  let notes: [Note]
  @Binding var selectedNoteID: UUID?
  @Environment(\.modelContext) private var modelContext
  @State private var showsCreation = false
  @State private var newTitle = ""
  @State private var newBody = ""
  @State private var saveFailed = false

  var body: some View {
    List(selection: $selectedNoteID) {
      ForEach(notes) { note in
        NavigationLink(value: note.id) {
          Text(note.title)
        }
        .accessibilityIdentifier("note-row-\(note.id.uuidString)")
        .accessibilityAddTraits(selectedNoteID == note.id ? .isSelected : [])
      }
    }
    .overlay {
      if project.notes.isEmpty {
        ContentUnavailableView {
          Label("Noteがありません", systemImage: "note.text")
            .accessibilityIdentifier("note-empty")
        } description: {
          Text("追加ボタンからNoteを作成しましょう。")
        }
      } else if notes.isEmpty {
        ContentUnavailableView {
          Label("検索結果がありません", systemImage: "magnifyingglass")
            .accessibilityIdentifier("note-search-empty")
        } description: {
          Text("このProject内に一致するNoteはありません。")
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
                selectedNoteID = note.id
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
