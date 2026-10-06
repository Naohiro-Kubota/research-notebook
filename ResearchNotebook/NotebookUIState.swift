import Foundation
import Observation

@MainActor
@Observable
final class NotebookUIState {
  var selectedProjectID: UUID?
  var selectedNoteID: UUID?
  var searchText = ""
  var selectedTagID: UUID?

  func reconcileSelection(visibleNoteIDs: Set<UUID>) {
    if let selectedNoteID, !visibleNoteIDs.contains(selectedNoteID) {
      self.selectedNoteID = nil
    }
  }
}
