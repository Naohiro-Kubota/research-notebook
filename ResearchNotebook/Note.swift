import Foundation
import SwiftData

@Model
final class Note {
  var id: UUID
  var title: String
  var body: String
  var project: Project?
  var tags: [Tag] = []

  init(id: UUID = UUID(), project: Project, title: String, body: String = "") {
    self.id = id
    self.title = title
    self.body = body
    self.project = project
  }
}
