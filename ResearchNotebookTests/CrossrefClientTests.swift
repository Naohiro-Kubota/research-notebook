import Foundation
import Testing

@testable import ResearchNotebook

@MainActor
@Suite(.serialized)
struct CrossrefClientTests {
  @Test func sendsEncodedQueryAndDecodesValidWorks() async throws {
    StubURLProtocol.handler = { request in
      StubURLProtocol.lastRequest = request
      return (
        Self.http(200),
        Data(
          #"{"message":{"items":[{"title":["  A Paper  "],"DOI":"10.1234/A","URL":"https://doi.org/10.1234/A"}]}}"#
            .utf8)
      )
    }
    let results = try await Self.client.search("  Swift & iPad  ")
    let requestURL = try #require(StubURLProtocol.lastRequest?.url)
    #expect(requestURL.scheme == "https")
    #expect(requestURL.host == "api.crossref.org")
    #expect(requestURL.path == "/works")
    let components = try #require(URLComponents(url: requestURL, resolvingAgainstBaseURL: false))
    #expect(
      components.queryItems?.first { $0.name == "query.bibliographic" }?.value == "Swift & iPad")
    #expect(components.queryItems?.first { $0.name == "rows" }?.value == "10")
    #expect(results.count == 1)
    #expect(results.first?.title == "A Paper")
    #expect(results.first?.doi == "10.1234/A")
    #expect(results.first?.url.absoluteString == "https://doi.org/10.1234/A")
  }

  @Test func rejectsBlankQueryWithoutSending() async {
    StubURLProtocol.lastRequest = nil
    StubURLProtocol.handler = { request in
      StubURLProtocol.lastRequest = request
      return (Self.http(200), Data())
    }
    await #expect(throws: CrossrefError.emptyQuery) { try await Self.client.search(" \n ") }
    #expect(StubURLProtocol.lastRequest == nil)
  }

  @Test func skipsIncompleteWorksAndAllowsEmptyResults() async throws {
    StubURLProtocol.handler = { _ in
      (
        Self.http(200),
        Data(
          #"{"message":{"items":[{"title":[],"DOI":"10.1/a","URL":"https://doi.org/10.1/a"},{"title":["Valid"],"DOI":"10.1/b","URL":"http://example.com"},{"title":["Good"],"DOI":"10.1/c","URL":"https://doi.org/10.1/c"},{"title":["Duplicate"],"DOI":"10.1/C","URL":"https://doi.org/10.1/C"},{"title":["No DOI"],"DOI":" ","URL":"https://doi.org/x"}]}}"#
            .utf8)
      )
    }
    #expect(try await Self.client.search("query").map(\.title) == ["Good"])
    StubURLProtocol.handler = { _ in (Self.http(200), Data(#"{"message":{"items":[]}}"#.utf8)) }
    #expect(try await Self.client.search("query").isEmpty)
  }

  @Test(arguments: [429, 500])
  func distinguishesHTTPFailure(status: Int) async {
    StubURLProtocol.handler = { _ in (Self.http(status), Data("error".utf8)) }
    await #expect(throws: CrossrefError.httpStatus(status)) {
      try await Self.client.search("query")
    }
  }

  @Test func distinguishesNonHTTPAndDecodeFailures() async {
    StubURLProtocol.handler = { _ in
      (
        URLResponse(
          url: URL(string: "https://api.crossref.org/works")!, mimeType: nil,
          expectedContentLength: 0, textEncodingName: nil), Data()
      )
    }
    await #expect(throws: CrossrefError.nonHTTPResponse) { try await Self.client.search("query") }
    StubURLProtocol.handler = { _ in (Self.http(200), Data("not JSON".utf8)) }
    await #expect(throws: CrossrefError.decoding) { try await Self.client.search("query") }
  }

  @Test func distinguishesTransportAndCancellation() async {
    StubURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }
    await #expect(throws: CrossrefError.transport) { try await Self.client.search("query") }
    let task = Task { try await Self.client.search("query") }
    task.cancel()
    await #expect(throws: CrossrefError.cancelled) { try await task.value }
  }

  private static var client: CrossrefClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [StubURLProtocol.self]
    return CrossrefClient(session: URLSession(configuration: configuration))
  }

  nonisolated private static func http(_ status: Int) -> HTTPURLResponse {
    HTTPURLResponse(
      url: URL(string: "https://api.crossref.org/works")!, statusCode: status, httpVersion: nil,
      headerFields: nil)!
  }
}

private final class StubURLProtocol: URLProtocol {
  nonisolated(unsafe) static var handler: @Sendable (URLRequest) throws -> (URLResponse, Data) = {
    _ in fatalError("No handler")
  }
  nonisolated(unsafe) static var lastRequest: URLRequest?
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    do {
      let (response, data) = try Self.handler(request)
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }
  override func stopLoading() {}
}
