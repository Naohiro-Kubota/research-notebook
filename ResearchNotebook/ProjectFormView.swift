import SwiftData
import SwiftUI

struct ProjectFormView: View {
  @Bindable var project: Project
  let onDeleted: () -> Void
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @State private var confirmsDeletion = false
  @State private var deletionFailed = false

  var body: some View {
    NavigationStack {
      Form {
        Section("タイトル（必須）") {
          ValidatedTitleField(
            title: $project.title, label: "Projectのタイトル",
            accessibilityID: "project-title-input")
        }
        Section("本文") {
          TextEditor(text: $project.body)
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
            do {
              let projectID = project.id
              try modelContext.delete(
                model: Project.self, where: #Predicate { $0.id == projectID })
              try modelContext.save()
              onDeleted()
              dismiss()
            } catch {
              modelContext.rollback()
              deletionFailed = true
            }
          }
        } message: {
          Text("このProjectと所属するすべてのNoteが削除されます。")
        }
      }
      .navigationTitle("Projectを編集")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("完了") { dismiss() }
            .accessibilityIdentifier("project-edit-done")
        }
      }
      .alert("Projectを削除できませんでした", isPresented: $deletionFailed) {
        Button("OK") {}
      }
    }
  }
}
