import Foundation
import SwiftData

// On the tested iPadOS 17.2 runtime, an entity named WebResource failed at initialization.
@Model
final class SavedWebResource {
  var id: UUID
  var title: String
  var doi: String
  var url: URL
  var project: Project?

  init(id: UUID = UUID(), project: Project, title: String, doi: String, url: URL) {
    self.id = id
    self.title = title
    self.doi = doi
    self.url = url
    self.project = project
  }
}

typealias WebResource = SavedWebResource
