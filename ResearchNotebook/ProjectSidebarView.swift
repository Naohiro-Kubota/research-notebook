import SwiftData
import SwiftUI

struct ProjectSidebarView: View {
  let projects: [Project]
  @Bindable var uiState: NotebookUIState
  @Environment(\.modelContext) private var modelContext
  @State private var showsCreation = false
  @State private var newTitle = ""
  @State private var newBody = ""
  @State private var saveFailed = false

  var body: some View {
    List(selection: $uiState.selectedProjectID) {
      ForEach(projects) { project in
        NavigationLink(value: project.id) {
          Text(project.title)
        }
        .accessibilityIdentifier("project-row-\(project.id.uuidString)")
        .accessibilityAddTraits(uiState.selectedProjectID == project.id ? .isSelected : [])
      }
    }
    .overlay {
      if projects.isEmpty {
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
              let project = Project(title: newTitle, body: newBody)
              modelContext.insert(project)
              if saveChanges(modelContext) {
                uiState.selectedNoteID = nil
                uiState.selectedProjectID = project.id
                showsCreation = false
              } else {
                modelContext.delete(project)
                saveFailed = true
              }
            }
            .disabled(!isValidTitle(newTitle))
            .accessibilityIdentifier("project-create")
          }
        }
        .alert("変更を保存できませんでした", isPresented: $saveFailed) {
          Button("OK") {}
        }
      }
    }
  }
}
