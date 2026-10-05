import SwiftData
import SwiftUI

struct NoteEditorView: View {
  @Bindable var note: Note
  let onDeleted: () -> Void
  @Environment(\.modelContext) private var modelContext
  @State private var confirmsDeletion = false
  @State private var deletionFailed = false
  @State private var saveFailed = false

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
      Section {
        Button("Noteを削除", role: .destructive) { confirmsDeletion = true }
          .accessibilityIdentifier("note-delete")
      }
      .alert("「\(note.title)」を削除しますか？", isPresented: $confirmsDeletion) {
        Button("キャンセル", role: .cancel) {}
        Button("削除", role: .destructive) {
          modelContext.delete(note)
          do {
            try modelContext.save()
            onDeleted()
          } catch {
            modelContext.rollback()
            deletionFailed = true
          }
        }
      } message: {
        Text("このNoteが削除されます。")
      }
    }
    .navigationTitle(note.title)
    .alert("Noteを削除できませんでした", isPresented: $deletionFailed) {
      Button("OK") {}
    }
    .alert("変更を保存できませんでした", isPresented: $saveFailed) {
      Button("OK") {}
    }
    .onChange(of: note.title) { _, _ in
      if !saveChanges(modelContext) {
        modelContext.rollback()
        saveFailed = true
      }
    }
    .onChange(of: note.body) { _, _ in
      if !saveChanges(modelContext) {
        modelContext.rollback()
        saveFailed = true
      }
    }
  }
}
