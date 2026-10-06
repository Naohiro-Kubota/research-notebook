# Phase 4 Web API 実装計画

> **For agentic workers:** 実装開始の明示指示を受けた後、`superpowers:executing-plans` で Task ごとに進める。本文の `- [ ]` は実装時の確認欄であり、この計画作成では着手しない。

**Goal:** Crossref の文献メタデータを検索し、結果を選択中の Project に Web Resource として保存・再参照できるようにする。

**Architecture:** `URLSession` と Crossref 専用 DTO で外部応答を扱い、画面用の結果へ変換する。Project に所属する `WebResource` だけを SwiftData に追加する。外部検索の一時状態は検索 UI が所有し、既存の Note 検索・選択状態とは混ぜない。

**Tech Stack:** Swift 6、iPadOS 17、SwiftUI、SwiftData、Foundation `URLSession`、Swift Concurrency、Swift Testing、XCTest UI Test。新規外部依存なし。

**Spec:** [承認済み Phase 4 要求](../../requirements/phase-4-web-api.md)、[ADR-0008](../../adr/0008-crossref-web-api-and-networking-boundary.md)、[ADR-0009](../../adr/0009-web-resource-persistence.md)。[ADR-0001](../../adr/0001-native-swiftui-data-flow.md)、[ADR-0002](../../adr/0002-testing-strategy.md)、[ADR-0004](../../adr/0004-three-column-notebook-navigation.md)、[ADR-0005](../../adr/0005-swiftdata-persistence.md)、[ADR-0007](../../adr/0007-observation-ui-state.md)を維持する。

## Global Constraints

- この計画は実装開始指示ではない。実装時に最新の `origin/develop` から専用ブランチ・Worktreeを用意し、変更・Build・Testはその中で行う。
- Crossref Public 枠、HTTPS、利用者の明示操作による検索。空白検索語を送らず、自動再試行・無限ページング・検索履歴を追加しない。
- DOI、タイトル、参照 URL だけを保存し、抄録・全文・API 応答全体・検索語を保存しない。秘密情報・外部ライブラリは追加しない。
- 既存 Project・Note・Tag と3列 Navigation、Note のタグ・ローカル検索・編集を維持する。手動 Simulator 操作は人間が行い、自動テストと記録を分ける。
- 同一 Project・DOI の再保存では重複を作らず既存項目を表示する。保存済み Web Resource は Project の Note 一覧に独立したセクションを設け、標準 `Link` で参照する。2026-10-06 に人間が両方を決定した。
- 旧ストアの自動移行が失敗した場合は元データを消去・置換せず、移行案と影響を人間に提示する。Navigation または Observation の採用方式を変える必要が出た場合も、実装を止めて該当 ADR の判断を受ける。

## Review Focus

| 入力・状態 | 期待する振る舞いと検証 Task |
|---|---|
| 空白だけの検索語 | 通信せず、入力を説明する。Task 2・3。 |
| Crossref の空タイトル配列、不正 URL | 不正データを保存しない。Task 2・4。 |
| HTTP 429、通信切断、不正 JSON | 原因に応じたエラー状態と再試行を表示する。Task 2・3。 |
| 検索変更・画面を閉じた後の遅延応答 | 古い結果・エラーで新しい状態を上書きしない。Task 3。 |
| 保存失敗・旧ストア・Project 削除 | 保存成功を偽装せず、既存データを保ち、所属 Web Resource を削除する。Task 1・4。 |

## Task 0: 既存 UI Test の失敗を切り分ける

**対象:** `ResearchNotebookUITests/ResearchNotebookUITests.swift`、必要と分かった既存の呼び出し元。Phase 4 の製品コードは変更しない。

- [ ] `testTagFilterCombinesWithSearchAndKeepsConditionsAcrossProjects` が計画作成時の基点でも失敗した記録を確認する。失敗は Project 切替後の Note 行 0 件で、全件実行と単独実行で再現した。
- [ ] 検索語の入力、選択 Project、表示対象 ID の変化を既存コードとテストログで追い、テスト操作と製品動作のどちらに原因があるか特定する。関連する `matchingNotes` と全呼び出し元を確認する。
- [ ] 原因がテストの操作・待機であればテストを最小修正し、製品の振る舞いであれば承認済み Phase 3 要求に沿って共通経路を最小修正する。期待結果を弱めたりテストを無効化したりしない。
- [ ] 対象テストを再実行して成功を確認する。原因と変更範囲を記録し、要求変更や別の重要設計判断が必要なら先へ進まず人間へ提示する。

## Task 1: Web Resource スキーマと旧ストア

**Files:** `ResearchNotebook/WebResource.swift` を作成。`ResearchNotebook/Project.swift`、`ResearchNotebook/ResearchNotebookApp.swift`、`ResearchNotebookTests/SwiftDataPersistenceTests.swift`、`ResearchNotebookTests/Fixtures/README.md` を更新。Phase 3 ストアのコピーを `ResearchNotebookTests/Fixtures/phase3.store` に追加する。

**Interface:** `WebResource(id: UUID = UUID(), project: Project, title: String, doi: String, url: URL)`。`Project.webResources: [WebResource]` は Project 削除時に `.cascade`。既存の Project・Note・Tag 属性を変更しない。

- [ ] モデル追加前の Phase 3 スキーマで、Project・Note・Tag を含むテスト用ストアを生成し、元データの ID・値・所属を `Fixtures/README.md` に記録する。元ファイルは以後変更しない。
- [ ] Swift Testing に、Web Resource の保存・別 Context からの再取得、Project 削除時の連鎖削除、旧ストアの**コピー**からのデータ保持を検証するテストを書く。新モデル未定義による失敗を確認する。
- [ ] `WebResource` と Project の Relationship、全 `ModelContainer` 構成へのモデル登録だけを追加する。テスト用コンテナも同じスキーマに更新する。
- [ ] 対象 Swift Testing を実行する。自動移行に失敗したら元ストアを保持して停止し、`SchemaMigrationPlan` の要否を人間へ提示する。
- [ ] Build・Lint と既存 Project・Note・Tag の保存テストを実行し、Task 1 の差分をコミットする。

## Task 2: Crossref クライアントと DTO

**Files:** `ResearchNotebook/CrossrefClient.swift`、`ResearchNotebookTests/CrossrefClientTests.swift` を作成する。

**Interface:** `CrossrefSearchResult` は `title: String`、`doi: String`、`url: URL` を持つ一時的な値型。`CrossrefClient(session: URLSession = .shared)` の `search(_ query: String) async throws -> [CrossrefSearchResult]` がこれを返す。エラーは通信、HTTP ステータス、非 HTTP 応答、デコード、キャンセルを区別する。API の `message.items` は専用 `Decodable` DTO で読み、各 Work の URL は文字列から検証して変換する。

- [ ] 注入した `URLSession` の応答をテストから制御し、検索語の URL エンコード、HTTPS の `/works` と `query.bibliographic`、空白語の送信拒否を検証する。成功、空配列、HTTP 429・500、非 HTTP 応答、不正 JSON、通信失敗、キャンセル、タイトル・DOI・URL の不正値のテストを先に失敗させる。
- [ ] 少数件の明示検索を実装する。HTTP ステータスをデコード前に検証し、DTO からタイトル・DOI・URL だけを変換する。保存可能な値を作れない Work は成功結果に混ぜない。不要な Protocol・Repository・自動再試行は作らない。
- [ ] 対象 Swift Testing、Build・Lint を実行し、API の公式仕様と異なる応答があれば実装前提を再調査して ADR と照合する。差分をコミットする。

## Task 3: 外部検索 UI と非同期状態

**Files:** `ResearchNotebook/CrossrefSearchView.swift` を作成し、`ResearchNotebook/ContentView.swift` に選択中 Project から開く入口を追加する。`ResearchNotebookUITests/ResearchNotebookUITests.swift` に重要フローを追加する。

**Interface:** 検索 View は `project: Project` を受け取り、検索語と `idle/loading/results/empty/error` を局所状態として所有する。`CrossrefClient.search(_:)` を利用者の検索操作で開始し、Project 名を保存先として示す。保存操作自体は Task 4 が接続する。

- [ ] UI Test に、検索語入力・明示検索、読み込み、空結果、エラーと再試行、キャンセル後の古い結果の抑止を先に記述する。実通信を使う UI Test は常時実行せず、既存の DEBUG 起動引数方式に合わせて固定応答を選べる最小のテスト用経路を設ける。
- [ ] `ProgressView`、`ContentUnavailableView` と標準の入力・ボタンで各状態を表示する。検索語を変更・画面を閉じたときは先行 Task をキャンセルし、完了順が逆でも新しい結果を上書きさせない。
- [ ] VoiceOver の検索・結果・再試行ラベル、Dynamic Type、キーボード到達をコードと自動 UI Test で確認する。画面の手動確認は人間に委ねる。
- [ ] 対象 Swift Testing・UI Test と Build・Lint を実行してコミットする。

## Task 4: 検索結果の保存と再参照

**Files:** `ResearchNotebook/WebResource.swift`、`ResearchNotebook/CrossrefSearchView.swift`、`ResearchNotebook/NoteListView.swift`、`ResearchNotebook/ProjectFormView.swift`、必要なら `ResearchNotebook/ContentView.swift` を更新。保存の振る舞いは `ResearchNotebookTests/SwiftDataPersistenceTests.swift`、主要フローは `ResearchNotebookUITests/ResearchNotebookUITests.swift` で確認する。

**Interface:** `saveWebResource(title: String, doi: String, url: URL, to project: Project, in context: ModelContext) throws -> WebResource` を `WebResource.swift` に置く。API DTO を受け取らず、既存の `saveChanges(_:)` を使う。同一 Project・DOI が既にあれば追加せずその項目を返す。Note 一覧内の独立した「Web Resources」セクションと、保存済み URL を開く標準 `Link` を使う。Note の `selectedNoteID` とローカル検索条件は変えない。

- [ ] Swift Testing に Project への保存、別 Context からの再読込、同一 Project・DOI の重複防止と既存項目の返却、別 Project では保存可能なこと、保存失敗、Project 削除と既存データ保持を記述し、失敗を確認する。
- [ ] 検索結果に保存操作を付け、重複時は既存項目を示す。保存失敗時は Context をロールバックしてエラーを表示する。保存済み一覧と Project 削除の説明を更新する。Note の編集・タグ・検索挙動は変えない。
- [ ] UI Test で検索結果の保存、再起動後の表示、指定 Project 以外に出ないこと、保存失敗の表示を確認する。保存済み Link が出典に進めることは URL とアクセシビリティラベルで検証する。
- [ ] 対象テスト、Build・Lint を実行してコミットする。

## Task 5: Phase 4 の総合確認と記録

**Files:** `docs/learning/phase-4.md`、`docs/requirements/phase-4-web-api.md`、必要な ADR とテストを更新する。

- [ ] [Definition of Done](../../development/definition-of-done.md)と承認済み Acceptance Criteria を項目ごとに照合し、公式資料の事実とアプリ固有の判断を学習ログへ記録する。
- [ ] `scripts/build.sh`、`scripts/lint.sh`、利用可能な iPad Simulator の UDID を指定した `scripts/test.sh`、`git diff --check` を実行する。Swift Testing と XCTest UI Test の結果、既存警告と新規警告を区別する。
- [ ] 人間へ可変ウインドウ幅、Dark Mode、Dynamic Type、VoiceOver、Keyboard での外部検索・保存・再参照を依頼し、報告された結果と未確認項目を自動テストと分けて記録する。未確認を完了扱いにしない。
- [ ] 対象外の変更や未承認判断がないことを確認する。完了条件を満たしたら作業ブランチを push し、`develop` 向けに日本語タイトル・本文の PR を作成する。
