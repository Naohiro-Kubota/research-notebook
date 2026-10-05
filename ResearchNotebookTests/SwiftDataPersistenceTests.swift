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

  @Test func readOnlyConfigurationRejectsSave() throws {
    let storeURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("store")
    do {
      let writable = try ModelContainer(
        for: Project.self, Note.self,
        configurations: ModelConfiguration(url: storeURL))
      let context = ModelContext(writable)
      context.insert(Project(title: "Existing"))
      try context.save()
    }
    let readOnly = ModelConfiguration(url: storeURL, allowsSave: false)
    let container = try ModelContainer(
      for: Project.self, Note.self, configurations: readOnly)
    let context = container.mainContext
    #expect(context.autosaveEnabled)
    #expect(try context.fetch(FetchDescriptor<Project>()).count == 1)
    context.insert(Project(title: "Research"))
    #expect(throws: (any Error).self) {
      try context.save()
    }
    let verifier = ModelContext(container)
    #expect(try verifier.fetch(FetchDescriptor<Project>()).map(\.title) == ["Existing"])
  }

  @Test func readOnlyConfigurationRejectsNoteInsertion() throws {
    let storeURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("store")
    do {
      let writable = try ModelContainer(
        for: Project.self, Note.self, configurations: ModelConfiguration(url: storeURL))
      let project = Project(title: "Existing")
      writable.mainContext.insert(project)
      writable.mainContext.insert(Note(project: project, title: "Existing note"))
      try writable.mainContext.save()
    }
    let readOnly = try ModelContainer(
      for: Project.self, Note.self,
      configurations: ModelConfiguration(url: storeURL, allowsSave: false))
    let context = readOnly.mainContext
    let project = try #require(context.fetch(FetchDescriptor<Project>()).first)
    context.insert(Note(project: project, title: "Unsaved"))
    #expect(context.hasChanges)
    #expect(throws: (any Error).self) { try context.save() }
  }

  @Test func deletingNoteKeepsOtherNotesAndProjects() throws {
    let container = try ModelContainer(
      for: Project.self, Note.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)
    let first = Project(title: "First")
    let second = Project(title: "Second")
    context.insert(first)
    context.insert(second)
    let deleted = Note(project: first, title: "Delete")
    context.insert(deleted)
    let retained = Note(project: first, title: "Keep")
    context.insert(retained)
    let other = Note(project: second, title: "Other")
    context.insert(other)
    let deletedID = deleted.id
    let retainedIDs = Set([retained.id, other.id])
    let projectIDs = Set([first.id, second.id])
    try context.save()

    let deletionContext = ModelContext(container)
    let savedNote = try #require(
      deletionContext.fetch(FetchDescriptor<Note>()).first { $0.id == deletedID })
    deletionContext.delete(savedNote)
    try deletionContext.save()

    let reader = ModelContext(container)
    #expect(Set(try reader.fetch(FetchDescriptor<Project>()).map(\.id)) == projectIDs)
    #expect(Set(try reader.fetch(FetchDescriptor<Note>()).map(\.id)) == retainedIDs)
  }

  @Test func deletingProjectCascadesOnDisk() throws {
    let storeURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("store")
    let deletedID = UUID()
    let retainedID = UUID()
    let retainedNoteID = UUID()
    do {
      let container = try ModelContainer(
        for: Project.self, Note.self,
        configurations: ModelConfiguration(url: storeURL))
      let context = ModelContext(container)
      let deleted = Project(id: deletedID, title: "Delete")
      let retained = Project(id: retainedID, title: "Keep")
      _ = Note(project: deleted, title: "Delete note")
      _ = Note(id: retainedNoteID, project: retained, title: "Keep note")
      context.insert(deleted)
      context.insert(retained)
      try context.save()
    }
    do {
      let container = try ModelContainer(
        for: Project.self, Note.self,
        configurations: ModelConfiguration(url: storeURL))
      let context = ModelContext(container)
      try context.delete(model: Project.self, where: #Predicate { $0.id == deletedID })
      try context.save()
    }
    let container = try ModelContainer(
      for: Project.self, Note.self,
      configurations: ModelConfiguration(url: storeURL))
    let reader = ModelContext(container)
    #expect(try reader.fetch(FetchDescriptor<Project>()).map(\.id) == [retainedID])
    #expect(try reader.fetch(FetchDescriptor<Note>()).map(\.id) == [retainedNoteID])
  }

}
