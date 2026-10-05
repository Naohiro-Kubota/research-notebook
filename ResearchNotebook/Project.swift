import Foundation
import SwiftData

func isValidTitle(_ title: String) -> Bool {
  !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}

@Model
final class Project {
  var id: UUID
  var title: String
  var body: String
  @Relationship(deleteRule: .cascade, inverse: \Note.project)
  var notes: [Note] = []

  init(id: UUID = UUID(), title: String, body: String = "") {
    self.id = id
    self.title = title
    self.body = body
  }
}
