import SwiftUI

struct CrossrefSearchView: View {
  let project: Project
  @Environment(\.dismiss) private var dismiss
  @State private var query = ""
  @State private var state: SearchState = .idle
  @State private var searchTask: Task<Void, Never>?
  @State private var activeSearch = UUID()
  private let client = CrossrefClient()

  private enum SearchState {
    case idle
    case loading
    case results([CrossrefSearchResult])
    case empty
    case error(CrossrefError)
  }

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 16) {
        Text("保存先: \(project.title)")
          .font(.headline)
          .accessibilityIdentifier("crossref-destination")
        Text("検索語はCrossrefへ送信されます。")
          .font(.footnote)
          .foregroundStyle(.secondary)
        HStack {
          TextField("文献を検索", text: $query)
            .textFieldStyle(.roundedBorder)
            .submitLabel(.search)
            .onSubmit(search)
            .accessibilityIdentifier("crossref-query")
          Button("検索", action: search)
            .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityIdentifier("crossref-search")
        }
        Group {
          switch state {
          case .idle:
            ContentUnavailableView("文献を検索", systemImage: "magnifyingglass")
          case .loading:
            HStack {
              ProgressView()
              Text("検索中")
                .accessibilityIdentifier("crossref-loading")
            }
          case .empty:
            ContentUnavailableView {
              Label("該当する文献がありません", systemImage: "magnifyingglass")
                .accessibilityIdentifier("crossref-empty")
            }
          case .error(let error):
            ContentUnavailableView {
              Label("検索できませんでした", systemImage: "exclamationmark.triangle")
                .accessibilityIdentifier("crossref-error")
            } description: {
              Text(error.message)
            } actions: {
              Button("再試行", action: search)
                .accessibilityIdentifier("crossref-retry")
            }
          case .results(let results):
            List(results) { result in
              VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                  .font(.headline)
                  .accessibilityIdentifier("crossref-result-title")
                Text(result.doi)
                  .font(.subheadline)
                Text(result.url.absoluteString)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              .accessibilityElement(children: .contain)
            }
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .padding()
      .navigationTitle("Crossrefで検索")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("閉じる") { dismiss() }
        }
      }
    }
    .onChange(of: query) { _, _ in
      cancelSearch()
      state = .idle
    }
    .onDisappear(perform: cancelSearch)
  }

  private func search() {
    let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !term.isEmpty else { return }
    cancelSearch()
    let token = activeSearch
    state = .loading
    searchTask = Task {
      do {
        let results = try await client.search(term)
        guard !Task.isCancelled, activeSearch == token else { return }
        state = results.isEmpty ? .empty : .results(results)
      } catch let error as CrossrefError {
        guard !Task.isCancelled, activeSearch == token, error != .cancelled else { return }
        state = .error(error)
      } catch {
        guard !Task.isCancelled, activeSearch == token else { return }
        state = .error(.transport)
      }
    }
  }

  private func cancelSearch() {
    searchTask?.cancel()
    searchTask = nil
    activeSearch = UUID()
  }
}

extension CrossrefError {
  fileprivate var message: String {
    switch self {
    case .emptyQuery: "検索語を入力してください。"
    case .transport: "通信を確認して再試行してください。"
    case .httpStatus(let status): "サーバーが応答しました（HTTP \(status)）。しばらくして再試行してください。"
    case .nonHTTPResponse, .decoding: "応答を読み取れませんでした。再試行してください。"
    case .cancelled: "検索を中断しました。"
    }
  }
}
