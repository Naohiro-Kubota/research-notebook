import Foundation
import SwiftData
import Testing

@testable import ResearchNotebook

@MainActor
struct SwiftDataPersistenceTests {
  @Test func persistsProjectAndNoteRelationship() throws {
    let container = try ModelContainer(
      for: Project.self, Note.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let writer = ModelContext(container)
    let projectID = UUID()
    let noteID = UUID()
    let project = Project(id: projectID, title: "Research", body: "Project body")
    _ = Note(id: noteID, project: project, title: "Observation", body: "Note body")
    writer.insert(project)
    try writer.save()

    let reader = ModelContext(container)
    let projects = try reader.fetch(FetchDescriptor<Project>())
    let notes = try reader.fetch(FetchDescriptor<Note>())
    let savedProject = try #require(projects.first)
    let savedNote = try #require(notes.first)
    #expect(projects.count == 1)
    #expect(notes.count == 1)
    #expect(savedProject.id == projectID)
    #expect(savedProject.title == "Research")
    #expect(savedProject.body == "Project body")
    #expect(savedProject.notes.map(\.id) == [noteID])
    #expect(savedNote.id == noteID)
    #expect(savedNote.project?.id == projectID)
    #expect(savedNote.title == "Observation")
    #expect(savedNote.body == "Note body")
  }

  @Test func allowsDuplicateTitlesWithDistinctIDs() throws {
    let container = try ModelContainer(
      for: Project.self, Note.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let writer = ModelContext(container)
    let first = Project(title: "Same")
    let second = Project(title: "Same")
    let firstNote = Note(project: first, title: "Same")
    let secondNote = Note(project: second, title: "Same")
    writer.insert(first)
    writer.insert(second)
    try writer.save()

    let reader = ModelContext(container)
    let projects = try reader.fetch(FetchDescriptor<Project>())
    let notes = try reader.fetch(FetchDescriptor<Note>())
    #expect(projects.count == 2)
    #expect(notes.count == 2)
    #expect(Set(projects.map(\.id)).count == 2)
    #expect(Set(notes.map(\.id)) == Set([firstNote.id, secondNote.id]))
    #expect(Set(notes.compactMap { $0.project?.id }) == Set(projects.map(\.id)))
  }

  @Test func rejectsBlankTitles() {
    #expect(!isValidTitle(" \n\t "))
    #expect(isValidTitle(" Research "))
  }

}
