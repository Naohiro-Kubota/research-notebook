import Foundation
import Testing

@testable import ResearchNotebook

@MainActor
struct NotebookUIStateTests {
  @Test func initialStateHasNoSelectionOrFilters() {
    let state = NotebookUIState()
    #expect(state.selectedProjectID == nil)
    #expect(state.selectedNoteID == nil)
    #expect(state.searchText.isEmpty)
    #expect(state.selectedTagID == nil)
  }

  @Test func visibleSelectionIsRetained() {
    let state = NotebookUIState()
    let noteID = UUID()
    state.selectedNoteID = noteID
    state.reconcileSelection(visibleNoteIDs: [noteID, UUID()])
    #expect(state.selectedNoteID == noteID)
  }

  @Test func hiddenSelectionIsClearedAndOtherStateIsPreserved() {
    let state = NotebookUIState()
    let projectID = UUID()
    let tagID = UUID()
    state.selectedProjectID = projectID
    state.selectedNoteID = UUID()
    state.searchText = "research"
    state.selectedTagID = tagID
    state.reconcileSelection(visibleNoteIDs: [UUID()])
    #expect(state.selectedNoteID == nil)
    #expect(state.selectedProjectID == projectID)
    #expect(state.searchText == "research")
    #expect(state.selectedTagID == tagID)
  }

  @Test func emptyVisibleNotesClearSelection() {
    let state = NotebookUIState()
    state.selectedNoteID = UUID()
    state.reconcileSelection(visibleNoteIDs: [])
    #expect(state.selectedNoteID == nil)
  }

  @Test func noSelectionRemainsEmptyWithVisibleNotes() {
    let state = NotebookUIState()
    state.reconcileSelection(visibleNoteIDs: [UUID()])
    #expect(state.selectedNoteID == nil)
  }

  @Test func switchingProjectClearsPreviousNoteAndKeepsFilters() {
    let state = NotebookUIState()
    let noteID = UUID()
    let tagID = UUID()
    state.selectedProjectID = UUID()
    state.selectedNoteID = noteID
    state.searchText = "research"
    state.selectedTagID = tagID
    state.reconcileSelection(visibleNoteIDs: [noteID])
    let nextProjectID = UUID()
    state.selectedProjectID = nextProjectID
    state.reconcileSelection(visibleNoteIDs: [UUID()])
    #expect(state.selectedProjectID == nextProjectID)
    #expect(state.selectedNoteID == nil)
    #expect(state.searchText == "research")
    #expect(state.selectedTagID == tagID)
  }

  @Test func instancesKeepIndependentState() {
    let first = NotebookUIState()
    let second = NotebookUIState()
    let projectID = UUID()
    let noteID = UUID()
    let tagID = UUID()
    first.selectedProjectID = projectID
    first.selectedNoteID = noteID
    first.searchText = "research"
    first.selectedTagID = tagID
    second.selectedProjectID = UUID()
    second.selectedNoteID = UUID()
    second.searchText = "other"
    second.selectedTagID = UUID()
    second.reconcileSelection(visibleNoteIDs: [])
    #expect(first.selectedProjectID == projectID)
    #expect(first.selectedNoteID == noteID)
    #expect(first.searchText == "research")
    #expect(first.selectedTagID == tagID)
    #expect(second.selectedNoteID == nil)
    #expect(second.searchText == "other")
  }
}
