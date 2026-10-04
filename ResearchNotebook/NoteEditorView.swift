import SwiftUI

struct NoteEditorView: View {
  @Binding var notebook: NotebookState
  let noteID: UUID

  private var note: NotebookNote? {
    notebook.notes.first { $0.id == noteID }
  }

  var body: some View {
    Form {
      if note != nil {
        Section("タイトル（必須）") {
          ValidatedTitleField(
            title: Binding(
              get: { note?.title ?? "" },
              set: { notebook.updateNoteTitle(id: noteID, title: $0) }
            ), label: "Noteのタイトル", accessibilityID: "note-title-input")
        }
        Section("本文") {
          TextEditor(
            text: Binding(
              get: { note?.body ?? "" },
              set: { notebook.updateNoteBody(id: noteID, body: $0) }
            )
          )
          .frame(minHeight: 240)
          .accessibilityLabel("Noteの本文")
          .accessibilityIdentifier("note-body-input")
        }
      }
    }
    .navigationTitle(note?.title ?? "Note")
  }
}
