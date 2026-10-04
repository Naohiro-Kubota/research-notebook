import SwiftUI

struct NoteListView: View {
  @Binding var notebook: NotebookState
  let projectID: UUID
  @State private var showsCreation = false
  @State private var newTitle = ""
  @State private var newBody = ""

  var body: some View {
    List(
      selection: Binding(
        get: { notebook.selectedNoteID },
        set: { notebook.selectNote($0) }
      )
    ) {
      ForEach(notebook.notes(in: projectID)) { note in
        NavigationLink(value: note.id) {
          Text(note.title)
        }
        .accessibilityIdentifier("note-row-\(note.id.uuidString)")
        .accessibilityAddTraits(notebook.selectedNoteID == note.id ? .isSelected : [])
      }
    }
    .overlay {
      if notebook.notes(in: projectID).isEmpty {
        ContentUnavailableView {
          Label("Noteがありません", systemImage: "note.text")
            .accessibilityIdentifier("note-empty")
        } description: {
          Text("追加ボタンからNoteを作成しましょう。")
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
              notebook.addNote(projectID: projectID, title: newTitle, body: newBody)
              showsCreation = false
            }
            .disabled(!NotebookState.isValidTitle(newTitle))
            .accessibilityIdentifier("note-create")
          }
        }
      }
    }
  }
}
