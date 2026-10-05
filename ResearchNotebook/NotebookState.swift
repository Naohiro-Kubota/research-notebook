import Foundation

struct NotebookProject: Identifiable, Equatable {
  let id: UUID
  var title: String
  var body: String
}

struct NotebookNote: Identifiable, Equatable {
  let id: UUID
  let projectID: UUID
  var title: String
  var body: String
}

struct NotebookState {
  private(set) var projects: [NotebookProject] = []
  private(set) var notes: [NotebookNote] = []
  private(set) var selectedProjectID: UUID? = nil
  private(set) var selectedNoteID: UUID? = nil

  static func isValidTitle(_ title: String) -> Bool {
    !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  @discardableResult
  mutating func addProject(id: UUID = UUID(), title: String, body: String = "") -> UUID? {
    guard Self.isValidTitle(title), !projects.contains(where: { $0.id == id }) else { return nil }
    projects.append(NotebookProject(id: id, title: title, body: body))
    selectProject(id)
    return id
  }

  @discardableResult
  mutating func addNote(id: UUID = UUID(), projectID: UUID, title: String, body: String = "")
    -> UUID?
  {
    guard Self.isValidTitle(title), projects.contains(where: { $0.id == projectID }),
      !notes.contains(where: { $0.id == id })
    else {
      return nil
    }
    notes.append(NotebookNote(id: id, projectID: projectID, title: title, body: body))
    selectProject(projectID)
    selectNote(id)
    return id
  }

  @discardableResult
  mutating func updateProjectTitle(id: UUID, title: String) -> Bool {
    guard Self.isValidTitle(title), let index = projects.firstIndex(where: { $0.id == id }) else {
      return false
    }
    projects[index].title = title
    return true
  }

  @discardableResult
  mutating func updateNoteTitle(id: UUID, title: String) -> Bool {
    guard Self.isValidTitle(title), let index = notes.firstIndex(where: { $0.id == id }) else {
      return false
    }
    notes[index].title = title
    return true
  }

  mutating func updateProjectBody(id: UUID, body: String) {
    guard let index = projects.firstIndex(where: { $0.id == id }) else { return }
    projects[index].body = body
  }

  mutating func updateNoteBody(id: UUID, body: String) {
    guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
    notes[index].body = body
  }

  mutating func selectProject(_ id: UUID?) {
    selectedProjectID = projects.first(where: { $0.id == id })?.id
    if !notes.contains(where: { $0.id == selectedNoteID && $0.projectID == selectedProjectID }) {
      selectedNoteID = nil
    }
  }

  mutating func selectNote(_ id: UUID?) {
    selectedNoteID = notes.first(where: { $0.id == id && $0.projectID == selectedProjectID })?.id
  }

  mutating func removeProject(id: UUID) {
    projects.removeAll { $0.id == id }
    notes.removeAll { $0.projectID == id }
    selectProject(selectedProjectID)
  }

  func notes(in projectID: UUID) -> [NotebookNote] {
    notes.filter { $0.projectID == projectID }
  }
}
