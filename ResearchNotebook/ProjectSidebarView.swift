import SwiftUI

struct ProjectSidebarView: View {
  @Binding var notebook: NotebookState
  @State private var showsCreation = false
  @State private var newTitle = ""
  @State private var newBody = ""

  var body: some View {
    List(
      selection: Binding(
        get: { notebook.selectedProjectID },
        set: { notebook.selectProject($0) }
      )
    ) {
      ForEach(notebook.projects) { project in
        NavigationLink(value: project.id) {
          Text(project.title)
        }
        .accessibilityIdentifier("project-row-\(project.id.uuidString)")
        .accessibilityAddTraits(notebook.selectedProjectID == project.id ? .isSelected : [])
      }
    }
    .overlay {
      if notebook.projects.isEmpty {
        ContentUnavailableView {
          Label("Projectがありません", systemImage: "folder")
            .accessibilityIdentifier("project-empty")
        } description: {
          Text("追加ボタンからProjectを作成し、研究のNoteを整理しましょう。")
        }
      }
    }
    .navigationTitle("Projects")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          newTitle = ""
          newBody = ""
          showsCreation = true
        } label: {
          Label("Projectを追加", systemImage: "plus")
        }
        .accessibilityIdentifier("project-add")
        .keyboardShortcut("n", modifiers: [.command, .shift])
      }
    }
    .sheet(isPresented: $showsCreation) {
      NavigationStack {
        Form {
          Section("タイトル（必須）") {
            TextField("Projectのタイトル", text: $newTitle)
              .accessibilityIdentifier("project-title-input")
          }
          Section("本文") {
            TextEditor(text: $newBody)
              .frame(minHeight: 160)
              .accessibilityLabel("Projectの本文")
              .accessibilityIdentifier("project-body-input")
          }
        }
        .navigationTitle("Projectを作成")
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("キャンセル") { showsCreation = false }
          }
          ToolbarItem(placement: .confirmationAction) {
            Button("作成") {
              notebook.addProject(title: newTitle, body: newBody)
              showsCreation = false
            }
            .disabled(!NotebookState.isValidTitle(newTitle))
            .accessibilityIdentifier("project-create")
          }
        }
      }
    }
  }
}
