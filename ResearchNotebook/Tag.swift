import Foundation
import SwiftData

@Model
final class Tag {
  var id: UUID
  var name: String
  @Relationship(deleteRule: .nullify, inverse: \Note.tags)
  var notes: [Note]? = []

  init(id: UUID = UUID(), name: String) {
    self.id = id
    self.name = name
  }
}
