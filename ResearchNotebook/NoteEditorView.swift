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
          NoteBodyEditor(
            noteID: noteID,
            text: Binding(
              get: { note?.body ?? "" },
              set: { notebook.updateNoteBody(id: noteID, body: $0) }
            )
          )
          .equatable()
          .frame(minHeight: 240)
          .accessibilityLabel("Noteの本文")
          .accessibilityIdentifier("note-body-input")
        }
      }
    }
    .navigationTitle(note?.title ?? "Note")
  }
}

private struct NoteBodyEditor: View, Equatable {
  let noteID: UUID
  @Binding var text: String
  @State private var draft: String

  init(noteID: UUID, text: Binding<String>) {
    self.noteID = noteID
    _text = text
    _draft = State(initialValue: text.wrappedValue)
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    // Phase 1 has one writer for this body. Keep notebook updates from
    // reevaluating the active input; the parent's .id resets it on note changes.
    lhs.noteID == rhs.noteID
  }

  var body: some View {
    TextEditor(text: $draft)
      .onChange(of: draft) { _, value in text = value }
  }
}
