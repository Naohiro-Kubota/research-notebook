import Foundation
import SwiftData

enum TagInputError: Error {
  case blankName
}

@MainActor
func attachTag(named input: String, to note: Note, in context: ModelContext) throws {
  let name = input.trimmingCharacters(in: .whitespacesAndNewlines)
  guard !name.isEmpty else { throw TagInputError.blankName }
  let tags = try context.fetch(FetchDescriptor<Tag>())
  let tag =
    tags.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    ?? Tag(name: name)
  if tag.modelContext == nil { context.insert(tag) }
  guard !note.tags.contains(where: { $0.id == tag.id }) else { return }
  note.tags.append(tag)
  do {
    try context.save()
  } catch {
    context.rollback()
    throw error
  }
}

@MainActor
func detachTag(_ tag: Tag, from note: Note, in context: ModelContext) throws {
  guard note.tags.contains(where: { $0.id == tag.id }) else { return }
  note.tags.removeAll { $0.id == tag.id }
  do {
    try context.save()
  } catch {
    context.rollback()
    throw error
  }
}
