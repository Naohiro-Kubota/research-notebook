import Foundation

struct CrossrefSearchResult: Identifiable, Sendable {
  var id: String { doi }
  let title: String
  let doi: String
  let url: URL
}

enum CrossrefError: Error, Equatable {
  case emptyQuery
  case transport
  case httpStatus(Int)
  case nonHTTPResponse
  case decoding
  case cancelled
}

struct CrossrefClient: Sendable {
  let session: URLSession

  init(session: URLSession = .shared) { self.session = session }

  func search(_ query: String) async throws -> [CrossrefSearchResult] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { throw CrossrefError.emptyQuery }
    do {
      try Task.checkCancellation()
      var components = URLComponents()
      components.scheme = "https"
      components.host = "api.crossref.org"
      components.path = "/works"
      components.queryItems = [
        URLQueryItem(name: "query.bibliographic", value: trimmed),
        URLQueryItem(name: "rows", value: "10"),
      ]
      guard let url = components.url else { throw CrossrefError.transport }
      let (data, response) = try await session.data(from: url)
      try Task.checkCancellation()
      guard let http = response as? HTTPURLResponse else { throw CrossrefError.nonHTTPResponse }
      guard (200...299).contains(http.statusCode) else {
        throw CrossrefError.httpStatus(http.statusCode)
      }
      let envelope: Envelope
      do {
        envelope = try JSONDecoder().decode(Envelope.self, from: data)
      } catch {
        throw CrossrefError.decoding
      }
      return envelope.message.items.compactMap { item in
        guard let title = item.title?.first?.trimmingCharacters(in: .whitespacesAndNewlines),
          !title.isEmpty,
          let doi = item.doi?.trimmingCharacters(in: .whitespacesAndNewlines),
          doi.hasPrefix("10."), doi.contains("/"),
          let rawURL = item.url, !rawURL.contains(where: \.isWhitespace),
          let url = URL(string: rawURL), url.scheme == "https", url.host != nil
        else { return nil }
        return CrossrefSearchResult(title: title, doi: doi, url: url)
      }
    } catch is CancellationError {
      throw CrossrefError.cancelled
    } catch let error as URLError where error.code == .cancelled {
      throw CrossrefError.cancelled
    } catch let error as CrossrefError {
      throw error
    } catch {
      throw CrossrefError.transport
    }
  }
}

private struct Envelope: Decodable {
  let message: Message

  struct Message: Decodable {
    let items: [Work]
  }

  struct Work: Decodable {
    let title: [String]?
    let doi: String?
    let url: String?

    enum CodingKeys: String, CodingKey {
      case title
      case doi = "DOI"
      case url = "URL"
    }
  }
}
