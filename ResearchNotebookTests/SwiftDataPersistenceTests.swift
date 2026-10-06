import Foundation
import SwiftData
import Testing

@testable import ResearchNotebook

@MainActor
struct SwiftDataPersistenceTests {
  @Test func savesWebResourceOncePerProjectAndDOI() throws {
    let container = try ModelContainer(
      for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)
    let first = Project(title: "First")
    let second = Project(title: "Second")
    context.insert(first)
    context.insert(second)
    let url = URL(string: "https://doi.org/10.1234/example")!
    let saved = try saveWebResource(
      title: "Paper", doi: "10.1234/EXAMPLE", url: url, to: first, in: context)
    let duplicate = try saveWebResource(
      title: "Changed", doi: "10.1234/example", url: url, to: first, in: context)
    let other = try saveWebResource(
      title: "Paper", doi: "10.1234/example", url: url, to: second, in: context)
    #expect(saved.id == duplicate.id)
    #expect(saved.title == "Paper")
    #expect(other.id != saved.id)
    let reader = ModelContext(container)
    #expect(try reader.fetch(FetchDescriptor<WebResource>()).count == 2)
    #expect(
      try reader.fetch(FetchDescriptor<Project>()).first { $0.id == first.id }?.webResources.count
        == 1)
  }

  @Test func failedWebResourceSaveDoesNotChangeExistingData() throws {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString).appendingPathExtension("store")
    do {
      let writable = try ModelContainer(
        for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
        configurations: ModelConfiguration(url: url))
      let context = writable.mainContext
      let project = Project(title: "Existing")
      context.insert(project)
      context.insert(Note(project: project, title: "Existing note"))
      try context.save()
    }
    let readOnly = try ModelContainer(
      for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
      configurations: ModelConfiguration(url: url, allowsSave: false))
    let context = readOnly.mainContext
    let project = try #require(context.fetch(FetchDescriptor<Project>()).first)
    #expect(throws: WebResourceSaveError.self) {
      try saveWebResource(
        title: "Unsaved", doi: "10.1234/unsaved",
        url: URL(string: "https://doi.org/10.1234/unsaved")!, to: project, in: context)
    }
    let verifier = ModelContext(readOnly)
    #expect(try verifier.fetch(FetchDescriptor<WebResource>()).isEmpty)
    #expect(try verifier.fetch(FetchDescriptor<Project>()).map(\.title) == ["Existing"])
    #expect(try verifier.fetch(FetchDescriptor<Note>()).map(\.title) == ["Existing note"])
  }

  @Test func persistsWebResourceAndCascadesWithProject() throws {
    let container = try ModelContainer(
      for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let writer = ModelContext(container)
    let project = Project(title: "Research")
    writer.insert(project)
    let resource = WebResource(
      project: project, title: "Paper", doi: "10.1234/paper",
      url: URL(string: "https://doi.org/10.1234/paper")!)
    writer.insert(resource)
    try writer.save()

    let reader = ModelContext(container)
    let saved = try #require(reader.fetch(FetchDescriptor<WebResource>()).first)
    #expect(saved.project?.id == project.id)
    #expect(saved.title == "Paper")
    #expect(saved.doi == "10.1234/paper")
    #expect(saved.url.absoluteString == "https://doi.org/10.1234/paper")
    #expect(try #require(reader.fetch(FetchDescriptor<Project>()).first).webResources.count == 1)

    let projectID = project.id
    try reader.delete(model: Project.self, where: #Predicate { $0.id == projectID })
    try reader.save()
    #expect(try ModelContext(container).fetch(FetchDescriptor<WebResource>()).isEmpty)
  }

  @Test func preservesPhase3StoreCopy() throws {
    let original = try #require(
      Bundle(for: Phase2FixtureBundle.self).url(forResource: "phase3", withExtension: "store"))
    let originalBytes = try Data(contentsOf: original)
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let copy = directory.appendingPathComponent("copy.store")
    try FileManager.default.copyItem(at: original, to: copy)
    let container = try ModelContainer(
      for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
      configurations: ModelConfiguration(url: copy))
    let reader = ModelContext(container)
    let projects = try reader.fetch(FetchDescriptor<Project>())
    let notes = try reader.fetch(FetchDescriptor<Note>())
    let tags = try reader.fetch(FetchDescriptor<ResearchNotebook.Tag>())
    #expect(projects.count == 2)
    #expect(notes.count == 2)
    #expect(tags.count == 1)
    #expect(try reader.fetch(FetchDescriptor<WebResource>()).isEmpty)
    let first = try #require(projects.first { $0.title == "Phase 3 project" })
    #expect(first.id.uuidString == "00000000-0000-0000-0000-000000000031")
    #expect(first.body == "Existing project body")
    #expect(first.notes.map(\.title) == ["Existing note"])
    #expect(first.notes.first?.id.uuidString == "00000000-0000-0000-0000-000000000033")
    #expect(first.notes.first?.body == "Note body")
    #expect(first.notes.first?.tags.map(\.name) == ["Shared"])
    #expect(first.webResources.isEmpty)
    let other = try #require(projects.first { $0.title == "Other project" })
    #expect(other.id.uuidString == "00000000-0000-0000-0000-000000000032")
    #expect(other.body == "Other body")
    #expect(other.notes.map(\.title) == ["Other note"])
    #expect(other.notes.first?.id.uuidString == "00000000-0000-0000-0000-000000000034")
    #expect(other.notes.first?.body == "Other note body")
    #expect(other.notes.first?.tags.map(\.name) == ["Shared"])
    #expect(tags.first?.notes?.count == 2)
    #expect(tags.first?.id.uuidString == "00000000-0000-0000-0000-000000000035")
    #expect(try Data(contentsOf: original) == originalBytes)
  }
  @Test func filtersSelectedProjectByTagAndSearchWithoutChangingNotes() throws {
    let container = try ModelContainer(
      for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)
    let first = Project(title: "First")
    let second = Project(title: "Second")
    context.insert(first)
    context.insert(second)
    let tag = ResearchNotebook.Tag(name: "Shared")
    context.insert(tag)
    let titleMatch = Note(project: first, title: "Apple", body: "One")
    titleMatch.tags = [tag]
    let bodyMatch = Note(project: first, title: "Other", body: "Apple body")
    bodyMatch.tags = [tag]
    _ = Note(project: first, title: "Apple without tag")
    let outside = Note(project: second, title: "Apple outside")
    outside.tags = [tag]
    let originalIDs = Set(first.notes.map(\.id))

    #expect(
      Set(matchingNotes(in: first, searchText: "", tagID: tag.id).map(\.id))
        == Set([titleMatch.id, bodyMatch.id]))
    #expect(
      Set(matchingNotes(in: first, searchText: "apple", tagID: tag.id).map(\.id))
        == Set([titleMatch.id, bodyMatch.id]))
    #expect(matchingNotes(in: first, searchText: "without", tagID: tag.id).isEmpty)
    #expect(matchingNotes(in: first, searchText: "apple", tagID: nil).count == 3)
    #expect(matchingNotes(in: first, searchText: "", tagID: nil).count == 3)
    #expect(Set(matchingNotes(in: second, searchText: "", tagID: tag.id).map(\.id)) == [outside.id])
    #expect(Set(first.notes.map(\.id)) == originalIDs)
    #expect(first.notes.count == 3)
  }

  @Test func searchesOnlySelectedProjectsNoteTitlesAndBodies() throws {
    let container = try ModelContainer(
      for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)
    let selected = Project(title: "Selected")
    let other = Project(title: "Other")
    context.insert(selected)
    context.insert(other)
    let titleMatch = Note(project: selected, title: "SwiftUI overview")
    let bodyMatch = Note(project: selected, title: "Notes", body: "A SwiftUI example")
    _ = Note(project: selected, title: "Unrelated")
    _ = Note(project: other, title: "SwiftUI outside")

    #expect(
      Set(matchingNotes(in: selected, searchText: "swiftui").map(\.id))
        == Set([titleMatch.id, bodyMatch.id]))
    #expect(matchingNotes(in: selected, searchText: "missing").isEmpty)
    #expect(matchingNotes(in: selected, searchText: "  ").count == 3)
  }

  @Test func persistsProjectAndNoteRelationship() throws {
    let container = try ModelContainer(
      for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
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
      for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
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
        for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
        configurations: ModelConfiguration(url: storeURL))
      let context = ModelContext(writable)
      context.insert(Project(title: "Existing"))
      try context.save()
    }
    let readOnly = ModelConfiguration(url: storeURL, allowsSave: false)
    let container = try ModelContainer(
      for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
      configurations: readOnly)
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
        for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
        configurations: ModelConfiguration(url: storeURL))
      let project = Project(title: "Existing")
      writable.mainContext.insert(project)
      writable.mainContext.insert(Note(project: project, title: "Existing note"))
      try writable.mainContext.save()
    }
    let readOnly = try ModelContainer(
      for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
      configurations: ModelConfiguration(url: storeURL, allowsSave: false))
    let context = readOnly.mainContext
    let project = try #require(context.fetch(FetchDescriptor<Project>()).first)
    context.insert(Note(project: project, title: "Unsaved"))
    #expect(context.hasChanges)
    #expect(throws: (any Error).self) { try context.save() }
  }

  @Test func deletingNoteKeepsOtherNotesAndProjects() throws {
    let container = try ModelContainer(
      for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
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
        for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
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
        for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
        configurations: ModelConfiguration(url: storeURL))
      let context = ModelContext(container)
      try context.delete(model: Project.self, where: #Predicate { $0.id == deletedID })
      try context.save()
    }
    let container = try ModelContainer(
      for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
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
        for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
        configurations: configuration)
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
        for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
        configurations: configuration)
    let reader = ModelContext(reopened)
    let notes = try reader.fetch(FetchDescriptor<Note>())
    #expect(notes.map(\.id) == [retainedID])
    #expect(notes.first?.tags.map(\.id) == [sharedID])
    let tags = try reader.fetch(FetchDescriptor<ResearchNotebook.Tag>())
    #expect(Set(tags.map(\.id)) == tagIDs)
    #expect(tags.first { $0.id == sharedID }?.notes?.map(\.id) == [retainedID])
    #expect((tags.first { $0.id != sharedID }?.notes ?? []).count == 0)
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
        for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
        configurations: configuration)
    let reader = ModelContext(reopened)
    #expect(try reader.fetch(FetchDescriptor<Project>()).map(\.id) == [retainedID])
    let notes = try reader.fetch(FetchDescriptor<Note>())
    #expect(notes.map(\.id) == [retainedNoteID])
    #expect(notes.first?.tags.map(\.id) == [sharedID])
    #expect(notes.first?.project?.id == retainedID)
    let tags = try reader.fetch(FetchDescriptor<ResearchNotebook.Tag>())
    #expect(Set(tags.map(\.id)) == tagIDs)
    #expect(tags.first { $0.id == sharedID }?.notes?.map(\.id) == [retainedNoteID])
    #expect((tags.first { $0.id != sharedID }?.notes ?? []).count == 0)
  }

  private func tagContainer(inMemory: Bool) throws -> (ModelContainer, ModelConfiguration) {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let configuration =
      inMemory
      ? ModelConfiguration(isStoredInMemoryOnly: true)
      : ModelConfiguration(url: directory.appendingPathComponent("tags.store"))
    let container = try ModelContainer(
      for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
      configurations: configuration)
    return (container, configuration)
  }

  @Test(arguments: [true, false])
  func normalizesAndReusesTagsAcrossProjects(inMemory: Bool) throws {
    let (container, configuration) = try tagContainer(inMemory: inMemory)
    let writer = ModelContext(container)
    let firstProject = Project(title: "First")
    let secondProject = Project(title: "Second")
    writer.insert(firstProject)
    writer.insert(secondProject)
    let first = Note(project: firstProject, title: "First note")
    let second = Note(project: secondProject, title: "Second note")
    writer.insert(first)
    writer.insert(second)
    try writer.save()

    #expect(throws: TagInputError.self) {
      try attachTag(named: " \n\t ", to: first, in: writer)
    }
    try attachTag(named: "  Research  ", to: first, in: writer)
    try attachTag(named: "RESEARCH", to: first, in: writer)
    try attachTag(named: "research", to: second, in: writer)
    let tagID = try #require(first.tags.first?.id)
    #expect(first.tags.count == 1)
    #expect(second.tags.count == 1)

    let reopened =
      inMemory
      ? container
      : try ModelContainer(
        for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
        configurations: configuration)
    let reader = ModelContext(reopened)
    let tags = try reader.fetch(FetchDescriptor<ResearchNotebook.Tag>())
    #expect(tags.count == 1)
    #expect(tags.first?.id == tagID)
    #expect(tags.first?.name == "Research")
    let notes = try reader.fetch(FetchDescriptor<Note>())
    #expect(notes.count == 2)
    #expect(notes.allSatisfy { $0.tags.map(\.id) == [tagID] })
    #expect(Set(notes.compactMap { $0.project?.id }) == Set([firstProject.id, secondProject.id]))
  }

  @Test func detachingTagKeepsItAndOtherNotes() throws {
    let (container, _) = try tagContainer(inMemory: true)
    let writer = ModelContext(container)
    let project = Project(title: "Project")
    writer.insert(project)
    let first = Note(project: project, title: "First")
    let second = Note(project: project, title: "Second")
    writer.insert(first)
    writer.insert(second)
    try writer.save()
    try attachTag(named: "Shared", to: first, in: writer)
    try attachTag(named: "shared", to: second, in: writer)
    let tag = try #require(first.tags.first)
    try detachTag(tag, from: first, in: writer)

    let reader = ModelContext(container)
    let notes = try reader.fetch(FetchDescriptor<Note>())
    #expect(notes.first { $0.id == first.id }?.tags.isEmpty == true)
    #expect(notes.first { $0.id == second.id }?.tags.map(\.id) == [tag.id])
    #expect(try reader.fetch(FetchDescriptor<ResearchNotebook.Tag>()).map(\.id) == [tag.id])
  }

  @Test func failedTagSaveKeepsExistingNotesAndTags() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = directory.appendingPathComponent("tags.store")
    do {
      let writable = try ModelContainer(
        for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
        configurations: ModelConfiguration(url: url))
      let context = ModelContext(writable)
      let project = Project(title: "Existing")
      context.insert(project)
      let first = Note(project: project, title: "First")
      let second = Note(project: project, title: "Second")
      context.insert(first)
      context.insert(second)
      try context.save()
      try attachTag(named: "Shared", to: first, in: context)
      try attachTag(named: "Shared", to: second, in: context)
    }
    let readOnly = try ModelContainer(
      for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
      configurations: ModelConfiguration(url: url, allowsSave: false))
    let context = ModelContext(readOnly)
    let notes = try context.fetch(FetchDescriptor<Note>())
    let first = try #require(notes.first { $0.title == "First" })
    let second = try #require(notes.first { $0.title == "Second" })
    let shared = try #require(first.tags.first)
    #expect(throws: (any Error).self) {
      try attachTag(named: "Unsaved", to: first, in: context)
    }
    #expect(throws: (any Error).self) {
      try detachTag(shared, from: second, in: context)
    }
    let verifier = ModelContext(readOnly)
    let savedNotes = try verifier.fetch(FetchDescriptor<Note>())
    #expect(savedNotes.count == 2)
    #expect(savedNotes.allSatisfy { $0.tags.map(\.name) == ["Shared"] })
    #expect(try verifier.fetch(FetchDescriptor<ResearchNotebook.Tag>()).map(\.name) == ["Shared"])
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
      for: Project.self, Note.self, ResearchNotebook.Tag.self, WebResource.self,
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
