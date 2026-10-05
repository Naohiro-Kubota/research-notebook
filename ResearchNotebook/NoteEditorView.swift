import SwiftUI

struct NoteEditorView: View {
  @Bindable var note: Note

  var body: some View {
    Form {
      Section("タイトル（必須）") {
        ValidatedTitleField(
          title: $note.title, label: "Noteのタイトル",
          accessibilityID: "note-title-input")
      }
      Section("本文") {
        TextEditor(text: $note.body)
          .frame(minHeight: 240)
          .accessibilityLabel("Noteの本文")
          .accessibilityIdentifier("note-body-input")
      }
    }
    .navigationTitle(note.title)
  }
}
