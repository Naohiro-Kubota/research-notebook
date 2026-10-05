import SwiftData
import SwiftUI

@main
struct ResearchNotebookApp: App {
  private let container = Result { try Self.makeContainer() }

  var body: some Scene {
    WindowGroup {
      switch container {
      case .success(let container):
        ContentView()
          .modelContainer(container)
      case .failure:
        ContentUnavailableView {
          Label("データを開けません", systemImage: "exclamationmark.triangle")
            .accessibilityIdentifier("store-open-error")
        } description: {
          Text("保存先を開けませんでした。アプリを再起動してください。")
        }
      }
    }
  }

  private static func makeContainer() throws -> ModelContainer {
    #if DEBUG
      let arguments = ProcessInfo.processInfo.arguments
      if arguments.contains("-uiTestingStoreFailure") {
        let url = URL(filePath: "/dev/null/research-notebook.store")
        return try ModelContainer(
          for: Project.self, Note.self, Tag.self,
          configurations: ModelConfiguration(url: url, allowsSave: false))
      }
      if let index = arguments.firstIndex(of: "-uiTestingReadOnlyStoreID"),
        arguments.indices.contains(index + 1),
        let storeID = UUID(uuidString: arguments[index + 1])
      {
        let directory = URL.applicationSupportDirectory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("UITest-\(storeID.uuidString).store")
        return try ModelContainer(
          for: Project.self, Note.self, Tag.self,
          configurations: ModelConfiguration(url: url, allowsSave: false))
      }
      if let index = arguments.firstIndex(of: "-uiTestingStoreID"),
        arguments.indices.contains(index + 1),
        let storeID = UUID(uuidString: arguments[index + 1])
      {
        let directory = URL.applicationSupportDirectory
        try FileManager.default.createDirectory(
          at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("UITest-\(storeID.uuidString).store")
        return try ModelContainer(
          for: Project.self, Note.self, Tag.self, configurations: ModelConfiguration(url: url))
      }
    #endif
    return try ModelContainer(for: Project.self, Note.self, Tag.self)
  }
}
