import Foundation
import SwiftData
import Testing

@testable import ResearchNotebook

@MainActor
struct SwiftDataPersistenceTests {
  @Test func persistsProjectAndNoteRelationship() throws {
    let container = try ModelContainer(
      for: Project.self, Note.self, ResearchNotebook.Tag.self,
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
      for: Project.self, Note.self, ResearchNotebook.Tag.self,
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
        for: Project.self, Note.self, ResearchNotebook.Tag.self,
        configurations: ModelConfiguration(url: storeURL))
      let context = ModelContext(writable)
      context.insert(Project(title: "Existing"))
      try context.save()
    }
    let readOnly = ModelConfiguration(url: storeURL, allowsSave: false)
    let container = try ModelContainer(
      for: Project.self, Note.self, ResearchNotebook.Tag.self, configurations: readOnly)
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
        for: Project.self, Note.self, ResearchNotebook.Tag.self,
        configurations: ModelConfiguration(url: storeURL))
      let project = Project(title: "Existing")
      writable.mainContext.insert(project)
      writable.mainContext.insert(Note(project: project, title: "Existing note"))
      try writable.mainContext.save()
    }
    let readOnly = try ModelContainer(
      for: Project.self, Note.self, ResearchNotebook.Tag.self,
      configurations: ModelConfiguration(url: storeURL, allowsSave: false))
    let context = readOnly.mainContext
    let project = try #require(context.fetch(FetchDescriptor<Project>()).first)
    context.insert(Note(project: project, title: "Unsaved"))
    #expect(context.hasChanges)
    #expect(throws: (any Error).self) { try context.save() }
  }

  @Test func deletingNoteKeepsOtherNotesAndProjects() throws {
    let container = try ModelContainer(
      for: Project.self, Note.self, ResearchNotebook.Tag.self,
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
        for: Project.self, Note.self, ResearchNotebook.Tag.self,
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
        for: Project.self, Note.self, ResearchNotebook.Tag.self,
        configurations: ModelConfiguration(url: storeURL))
      let context = ModelContext(container)
      try context.delete(model: Project.self, where: #Predicate { $0.id == deletedID })
      try context.save()
    }
    let container = try ModelContainer(
      for: Project.self, Note.self, ResearchNotebook.Tag.self,
      configurations: ModelConfiguration(url: storeURL))
    let reader = ModelContext(container)
    #expect(try reader.fetch(FetchDescriptor<Project>()).map(\.id) == [retainedID])
    #expect(try reader.fetch(FetchDescriptor<Note>()).map(\.id) == [retainedNoteID])
  }

  @Test(arguments: [true, false])
  func sharesTagsAcrossProjectsAfterReopening(inMemory: Bool) throws {
    let (container, configuration) = try tagContainer(inMemory: inMemory)
    let context = ModelContext(container)
    let first = Project(title: "First")
    let second = Project(title: "Second")
    context.insert(first)
    context.insert(second)
    let firstNote = Note(project: first, title: "First note")
    let secondNote = Note(project: second, title: "Second note")
    context.insert(firstNote)
    context.insert(secondNote)
    let shared = ResearchNotebook.Tag(name: "Shared")
    let other = ResearchNotebook.Tag(name: "Other")
    context.insert(shared)
    context.insert(other)
    let sharedID = shared.id
    let otherID = other.id
    firstNote.tags = [shared, other]
    secondNote.tags = [shared]
    try context.save()

    let reopened =
      inMemory
      ? container
      : try ModelContainer(
        for: Project.self, Note.self, ResearchNotebook.Tag.self, configurations: configuration)
    let reader = ModelContext(reopened)
    let notes = try reader.fetch(FetchDescriptor<Note>())
    let savedFirst = try #require(notes.first { $0.id == firstNote.id })
    let savedSecond = try #require(notes.first { $0.id == secondNote.id })
    #expect(Set(savedFirst.tags.map(\.id)) == Set([sharedID, otherID]))
    #expect(savedSecond.tags.map(\.id) == [sharedID])
    #expect(savedFirst.tags.first { $0.id == sharedID } === savedSecond.tags.first)
    #expect(try reader.fetch(FetchDescriptor<ResearchNotebook.Tag>()).count == 2)
    #expect(savedSecond.tags.first?.name == "Shared")
    #expect(
      Set(savedSecond.tags.first?.notes?.map(\.id) ?? []) == Set([firstNote.id, secondNote.id]))
  }

  @Test(arguments: [true, false])
  func deletingTaggedNoteKeepsSharedAndUnusedTags(inMemory: Bool) throws {
    let (container, configuration) = try tagContainer(inMemory: inMemory)
    let context = ModelContext(container)
    let project = Project(title: "Project")
    context.insert(project)
    let deleted = Note(project: project, title: "Delete")
    let retained = Note(project: project, title: "Keep")
    context.insert(deleted)
    context.insert(retained)
    let shared = ResearchNotebook.Tag(name: "Shared")
    let unused = ResearchNotebook.Tag(name: "Unused after deletion")
    context.insert(shared)
    context.insert(unused)
    let tagIDs = Set([shared.id, unused.id])
    let sharedID = shared.id
    let retainedID = retained.id
    deleted.tags = [shared, unused]
    retained.tags = [shared]
    try context.save()
    context.delete(deleted)
    try context.save()

    let reopened =
      inMemory
      ? container
      : try ModelContainer(
        for: Project.self, Note.self, ResearchNotebook.Tag.self, configurations: configuration)
    let reader = ModelContext(reopened)
    let notes = try reader.fetch(FetchDescriptor<Note>())
    #expect(notes.map(\.id) == [retainedID])
    #expect(notes.first?.tags.map(\.id) == [sharedID])
    let tags = try reader.fetch(FetchDescriptor<ResearchNotebook.Tag>())
    #expect(Set(tags.map(\.id)) == tagIDs)
    #expect(tags.first { $0.id == sharedID }?.notes?.map(\.id) == [retainedID])
    #expect((tags.first { $0.id != sharedID }?.notes ?? []).isEmpty)
    #expect(try reader.fetch(FetchDescriptor<Project>()).map(\.id) == [project.id])
  }

  @Test(arguments: [true, false])
  func deletingProjectWithTaggedNotesKeepsSharedAndUnusedTags(inMemory: Bool) throws {
    let (container, configuration) = try tagContainer(inMemory: inMemory)
    let writer = ModelContext(container)
    let deleted = Project(title: "Delete")
    let retained = Project(title: "Keep")
    writer.insert(deleted)
    writer.insert(retained)
    let deletedNote = Note(project: deleted, title: "Delete note")
    let retainedNote = Note(project: retained, title: "Keep note")
    writer.insert(deletedNote)
    writer.insert(retainedNote)
    let shared = ResearchNotebook.Tag(name: "Shared")
    let unused = ResearchNotebook.Tag(name: "Unused after deletion")
    writer.insert(shared)
    writer.insert(unused)
    let deletedID = deleted.id
    let retainedID = retained.id
    let retainedNoteID = retainedNote.id
    let sharedID = shared.id
    let tagIDs = Set([shared.id, unused.id])
    deletedNote.tags = [shared, unused]
    retainedNote.tags = [shared]
    try writer.save()

    let deletionContext = ModelContext(container)
    try deletionContext.delete(model: Project.self, where: #Predicate { $0.id == deletedID })
    try deletionContext.save()
    let reopened =
      inMemory
      ? container
      : try ModelContainer(
        for: Project.self, Note.self, ResearchNotebook.Tag.self, configurations: configuration)
    let reader = ModelContext(reopened)
    #expect(try reader.fetch(FetchDescriptor<Project>()).map(\.id) == [retainedID])
    let notes = try reader.fetch(FetchDescriptor<Note>())
    #expect(notes.map(\.id) == [retainedNoteID])
    #expect(notes.first?.tags.map(\.id) == [sharedID])
    #expect(notes.first?.project?.id == retainedID)
    let tags = try reader.fetch(FetchDescriptor<ResearchNotebook.Tag>())
    #expect(Set(tags.map(\.id)) == tagIDs)
    #expect(tags.first { $0.id == sharedID }?.notes?.map(\.id) == [retainedNoteID])
    #expect((tags.first { $0.id != sharedID }?.notes ?? []).isEmpty)
  }

  private func tagContainer(inMemory: Bool) throws -> (ModelContainer, ModelConfiguration) {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let configuration =
      inMemory
      ? ModelConfiguration(isStoredInMemoryOnly: true)
      : ModelConfiguration(url: directory.appendingPathComponent("tags.store"))
    let container = try ModelContainer(
      for: Project.self, Note.self, ResearchNotebook.Tag.self,
      configurations: configuration)
    return (container, configuration)
  }

  @Test func preservesPhase2StoreCopy() throws {
    let original = try #require(
      Bundle(for: Phase2FixtureBundle.self)
        .url(forResource: "phase2", withExtension: "store"))
    let originalBytes = try Data(contentsOf: original)
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let copy = directory.appendingPathComponent("copy.store")
    try FileManager.default.copyItem(at: original, to: copy)
    let container = try ModelContainer(
      for: Project.self, Note.self, ResearchNotebook.Tag.self,
      configurations: ModelConfiguration(url: copy))
    let reader = ModelContext(container)
    let projects = try reader.fetch(FetchDescriptor<Project>())
    let notes = try reader.fetch(FetchDescriptor<Note>())
    #expect(projects.count == 2)
    #expect(notes.count == 4)
    #expect(try reader.fetch(FetchDescriptor<ResearchNotebook.Tag>()).isEmpty)
    for index in 1...2 {
      let projectID = try #require(UUID(uuidString: "00000000-0000-0000-0000-00000000000\(index)"))
      let project = try #require(projects.first { $0.id == projectID })
      #expect(project.title == "Project \(index)")
      #expect(project.body == "Project body \(index)")
      #expect(project.notes.count == 2)
      for number in 1...2 {
        let noteID = try #require(
          UUID(uuidString: "00000000-0000-0000-0000-0000000000\(index)\(number)"))
        let note = try #require(notes.first { $0.id == noteID })
        #expect(note.title == "Note \(index)-\(number)")
        #expect(note.body == "本文 \(index)-\(number)")
        #expect(note.project?.id == projectID)
        #expect(project.notes.contains { $0.id == noteID })
        #expect(note.tags.isEmpty)
      }
    }
    #expect(try Data(contentsOf: original) == originalBytes)
  }

}

private final class Phase2FixtureBundle: NSObject {}
