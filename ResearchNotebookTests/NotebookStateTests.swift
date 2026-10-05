import Foundation
import Testing

@testable import ResearchNotebook

@MainActor
struct NotebookStateTests {
  @Test func rejectsBlankTitles() throws {
    var state = NotebookState()
    #expect(!NotebookState.isValidTitle("  \n\t"))
    let blankProject = state.addProject(title: "  ")
    #expect(blankProject == nil)
    let createdProject = state.addProject(title: "Research")
    let project = try #require(createdProject)
    #expect(state.projects.first?.body == "")
    #expect(state.selectedProjectID == project)
    let blankNote = state.addNote(projectID: project, title: "\n")
    #expect(blankNote == nil)
    let createdNote = state.addNote(projectID: project, title: "Observation")
    let note = try #require(createdNote)
    #expect(state.notes.first?.body == "")
    #expect(state.selectedNoteID == note)
  }

  @Test func keepsDistinctIDsForDuplicateTitles() throws {
    var state = NotebookState()
    let firstProject = state.addProject(title: "Same")
    let first = try #require(firstProject)
    let secondProject = state.addProject(title: "Same")
    let second = try #require(secondProject)
    #expect(first != second)
    let createdFirstNote = state.addNote(projectID: first, title: "Same")
    let firstNote = try #require(createdFirstNote)
    let createdSecondNote = state.addNote(projectID: first, title: "Same")
    let secondNote = try #require(createdSecondNote)
    #expect(firstNote != secondNote)
    #expect(state.projects.count == 2)
    #expect(state.notes(in: first).map(\.id) == [firstNote, secondNote])
    #expect(state.notes(in: second).isEmpty)
    #expect(state.selectedProjectID == first)
    #expect(state.selectedNoteID == secondNote)
  }

  @Test func rejectsDuplicateProjectIDWithoutChangingState() throws {
    var state = NotebookState()
    let duplicateID = UUID()
    let originalProject = state.addProject(
      id: duplicateID, title: "Original", body: "Original body")
    _ = try #require(originalProject)
    let selectedProject = state.addProject(title: "Selected")
    let selected = try #require(selectedProject)
    let selectedNote = state.addNote(projectID: selected, title: "Selected note")
    let note = try #require(selectedNote)
    let projects = state.projects
    let notes = state.notes

    let duplicate = state.addProject(
      id: duplicateID, title: "Replacement", body: "Replacement body")

    #expect(duplicate == nil)
    #expect(state.projects == projects)
    #expect(state.notes == notes)
    #expect(state.selectedProjectID == selected)
    #expect(state.selectedNoteID == note)
  }

  @Test func rejectsDuplicateNoteIDWithoutChangingState() throws {
    var state = NotebookState()
    let firstProject = state.addProject(title: "First")
    let first = try #require(firstProject)
    let secondProject = state.addProject(title: "Second")
    let second = try #require(secondProject)
    let duplicateID = UUID()
    let originalNote = state.addNote(
      id: duplicateID, projectID: first, title: "Original", body: "Original body")
    _ = try #require(originalNote)
    let selectedNote = state.addNote(projectID: second, title: "Selected note")
    let note = try #require(selectedNote)
    let projects = state.projects
    let notes = state.notes

    let duplicate = state.addNote(
      id: duplicateID, projectID: first, title: "Replacement", body: "Replacement body")

    #expect(duplicate == nil)
    #expect(state.projects == projects)
    #expect(state.notes == notes)
    #expect(state.selectedProjectID == second)
    #expect(state.selectedNoteID == note)
  }

  @Test func allowsSameIDAcrossProjectsAndNotes() throws {
    var state = NotebookState()
    let sharedID = UUID()
    let createdProject = state.addProject(id: sharedID, title: "Project")
    let project = try #require(createdProject)
    let createdNote = state.addNote(id: sharedID, projectID: project, title: "Note")
    #expect(createdNote == sharedID)
    let anotherID = UUID()
    let anotherNote = state.addNote(id: anotherID, projectID: project, title: "Another note")
    _ = try #require(anotherNote)
    let anotherProject = state.addProject(id: anotherID, title: "Another project")
    #expect(anotherProject == anotherID)
    #expect(state.projects.map(\.id) == [sharedID, anotherID])
    #expect(state.notes.map(\.id) == [sharedID, anotherID])
  }

  @Test func rejectsNoteForMissingProject() {
    var state = NotebookState()
    let missingProjectNote = state.addNote(projectID: UUID(), title: "Note")
    #expect(missingProjectNote == nil)
    #expect(state.notes.isEmpty)
    #expect(state.selectedProjectID == nil)
    #expect(state.selectedNoteID == nil)
  }

  @Test func updatesOnlyValidTitles() throws {
    var state = NotebookState()
    let createdProject = state.addProject(title: "Project", body: "Initial")
    let project = try #require(createdProject)
    let createdNote = state.addNote(projectID: project, title: "Note", body: "Initial")
    let note = try #require(createdNote)
    let validProjectTitle = state.updateProjectTitle(id: project, title: "Renamed project")
    #expect(validProjectTitle)
    let validNoteTitle = state.updateNoteTitle(id: note, title: "Renamed note")
    #expect(validNoteTitle)
    let blankProjectTitle = state.updateProjectTitle(id: project, title: " \n")
    #expect(!blankProjectTitle)
    let blankNoteTitle = state.updateNoteTitle(id: note, title: "")
    #expect(!blankNoteTitle)
    let missingProjectTitle = state.updateProjectTitle(id: UUID(), title: "Missing")
    #expect(!missingProjectTitle)
    let missingNoteTitle = state.updateNoteTitle(id: UUID(), title: "Missing")
    #expect(!missingNoteTitle)
    state.updateProjectBody(id: project, body: "Project body")
    state.updateNoteBody(id: note, body: "Note body")
    state.updateProjectBody(id: UUID(), body: "Missing")
    state.updateNoteBody(id: UUID(), body: "Missing")
    #expect(state.projects.first?.title == "Renamed project")
    #expect(state.notes.first?.title == "Renamed note")
    #expect(state.projects.first?.body == "Project body")
    #expect(state.notes.first?.body == "Note body")
    state.updateProjectBody(id: project, body: "")
    state.updateNoteBody(id: note, body: "")
    #expect(state.projects.first?.body == "")
    #expect(state.notes.first?.body == "")
  }

  @Test func clearsNoteSelectionWhenProjectChanges() throws {
    var state = NotebookState()
    let firstProject = state.addProject(title: "First")
    let first = try #require(firstProject)
    let secondProject = state.addProject(title: "Second")
    let second = try #require(secondProject)
    let createdNote = state.addNote(projectID: first, title: "Note")
    let note = try #require(createdNote)
    state.selectProject(first)
    #expect(state.selectedNoteID == note)
    state.selectProject(second)
    #expect(state.selectedNoteID == nil)
    state.selectNote(note)
    #expect(state.selectedNoteID == nil)
    state.selectProject(first)
    state.selectNote(note)
    #expect(state.selectedNoteID == note)
    state.selectNote(nil)
    #expect(state.selectedNoteID == nil)
    state.selectNote(note)
    state.selectProject(nil)
    #expect(state.selectedProjectID == nil)
    #expect(state.selectedNoteID == nil)
    state.selectProject(UUID())
    #expect(state.selectedProjectID == nil)
    state.selectProject(first)
    state.selectNote(UUID())
    #expect(state.selectedNoteID == nil)
  }

  @Test func removesOnlyDeletedProjectsNotes() throws {
    var state = NotebookState()
    let firstProject = state.addProject(title: "First")
    let first = try #require(firstProject)
    let secondProject = state.addProject(title: "Second")
    let second = try #require(secondProject)
    let createdFirstNote = state.addNote(projectID: first, title: "First note")
    _ = try #require(createdFirstNote)
    let createdRetainedNote = state.addNote(projectID: second, title: "Second note")
    let retained = try #require(createdRetainedNote)
    state.removeProject(id: UUID())
    state.removeProject(id: first)
    #expect(state.projects.map(\.id) == [second])
    #expect(state.notes.map(\.id) == [retained])
    #expect(state.selectedProjectID == second)
    #expect(state.selectedNoteID == retained)
    state.removeProject(id: second)
    #expect(state.projects.isEmpty)
    #expect(state.notes.isEmpty)
    #expect(state.selectedProjectID == nil)
    #expect(state.selectedNoteID == nil)
  }
}
