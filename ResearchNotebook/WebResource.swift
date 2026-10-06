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

enum WebResourceSaveError: Error {
  case invalidInput
  case failed
}

@MainActor
func saveWebResource(
  title: String, doi: String, url: URL, to project: Project, in context: ModelContext
) throws -> WebResource {
  let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
  let doi = doi.trimmingCharacters(in: .whitespacesAndNewlines)
  guard !title.isEmpty, doi.hasPrefix("10."), doi.contains("/"), url.scheme == "https",
    url.host != nil
  else { throw WebResourceSaveError.invalidInput }
  if let existing = project.webResources.first(where: {
    $0.doi.caseInsensitiveCompare(doi) == .orderedSame
  }) {
    return existing
  }
  let resource = WebResource(project: project, title: title, doi: doi, url: url)
  context.insert(resource)
  guard saveChanges(context) else {
    context.delete(resource)
    throw WebResourceSaveError.failed
  }
  return resource
}
