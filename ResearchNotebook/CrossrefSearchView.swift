import SwiftData
import SwiftUI

struct CrossrefSearchView: View {
  let project: Project
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @State private var query = ""
  @State private var state: SearchState = .idle
  @State private var searchTask: Task<Void, Never>?
  @State private var activeSearch = UUID()
  @State private var saveNotice: SaveNotice?
  @State private var saveFailed = false
  private let client = CrossrefClient()

  private enum SearchState {
    case idle
    case loading
    case results([CrossrefSearchResult])
    case empty
    case error(CrossrefError)
  }

  private enum SaveNotice {
    case saved
    case existing
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
                Button("Projectに保存") { save(result) }
                  .accessibilityIdentifier("crossref-save")
                if let saved = project.webResources.first(where: {
                  $0.doi.caseInsensitiveCompare(result.doi) == .orderedSame
                }) {
                  Link("保存済みの出典を開く", destination: saved.url)
                }
              }
              .accessibilityElement(children: .contain)
            }
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        if let saveNotice {
          switch saveNotice {
          case .saved:
            Text("このProjectに保存しました")
              .accessibilityIdentifier("crossref-saved")
          case .existing:
            Text("同じDOIの保存済み項目を表示しています")
              .accessibilityIdentifier("crossref-existing")
          }
        }
        if saveFailed {
          Label("保存できませんでした", systemImage: "exclamationmark.triangle")
            .foregroundStyle(.red)
            .accessibilityIdentifier("crossref-save-error")
        }
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
      saveNotice = nil
      saveFailed = false
    }
    .onDisappear(perform: cancelSearch)
  }

  private func search() {
    let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !term.isEmpty else { return }
    saveFailed = false
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

  private func save(_ result: CrossrefSearchResult) {
    let exists = project.webResources.contains {
      $0.doi.caseInsensitiveCompare(result.doi) == .orderedSame
    }
    do {
      _ = try saveWebResource(
        title: result.title, doi: result.doi, url: result.url,
        to: project, in: modelContext)
      saveFailed = false
      saveNotice = exists ? .existing : .saved
    } catch {
      saveNotice = nil
      saveFailed = true
    }
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
