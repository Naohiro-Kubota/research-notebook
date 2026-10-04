import SwiftUI

struct ProjectFormView: View {
  @Binding var notebook: NotebookState
  let projectID: UUID
  @Environment(\.dismiss) private var dismiss
  @State private var confirmsDeletion = false

  private var project: NotebookProject? {
    notebook.projects.first { $0.id == projectID }
  }

  var body: some View {
    NavigationStack {
      Form {
        if let project {
          Section("タイトル（必須）") {
            ValidatedTitleField(
              title: Binding(
                get: { self.project?.title ?? "" },
                set: { notebook.updateProjectTitle(id: projectID, title: $0) }
              ), label: "Projectのタイトル", accessibilityID: "project-title-input")
          }
          Section("本文") {
            TextEditor(
              text: Binding(
                get: { self.project?.body ?? "" },
                set: { notebook.updateProjectBody(id: projectID, body: $0) }
              )
            )
            .frame(minHeight: 160)
            .accessibilityLabel("Projectの本文")
            .accessibilityIdentifier("project-body-input")
          }
          Section {
            Button("Projectを削除", role: .destructive) { confirmsDeletion = true }
              .accessibilityIdentifier("project-delete")
          }
          .alert("「\(project.title)」を削除しますか？", isPresented: $confirmsDeletion) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
              notebook.removeProject(id: projectID)
              dismiss()
            }
          } message: {
            Text("このProjectと所属するすべてのNoteが削除されます。")
          }
        }
      }
      .navigationTitle("Projectを編集")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("完了") { dismiss() }
            .accessibilityIdentifier("project-edit-done")
        }
      }
    }
  }
}
