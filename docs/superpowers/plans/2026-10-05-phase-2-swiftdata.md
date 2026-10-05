# Phase 2 SwiftData 永続化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Project と Note をローカルに自動保存し、再起動後に復元できるようにする。Note 単体削除と Project 削除時の連鎖削除を加える。

**Architecture:** 承認済み ADR-0005 の A 案に従い、Project と Note を SwiftData の `@Model` として定義する。View は `@Query` と環境の `ModelContext` を使い、選択 ID は UI 状態として保持する。保存ボタンは置かない。

**Tech Stack:** iPadOS 17、Swift 6 言語モード、SwiftUI、SwiftData、Swift Testing、XCTest UI Test。外部依存なし。

**Spec:** `docs/requirements/phase-2-swiftdata.md`、`docs/adr/0005-swiftdata-persistence.md`

## Global Constraints

- Phase 1 の必須タイトル、空本文可、同名を許す ID、画面上の即時反映、3 列 Navigation を維持する。
- 有効な変更を自動保存し、保存ボタンを置かない。成功を確認していない変更を「保存済み」と表示しない。
- Project 削除で所属 Note を削除する。Note 単体削除では他の Note と Project を残す。
- iCloud 同期、外部 API、外部依存、Phase 1 のメモリデータ移行、将来用の Migration Plan は追加しない。
- 外部依存、外部 API、破壊的なデータモデル変更、プライバシーに影響する設計が必要になれば、人間と別途判断する。
- 実装開始は人間の明示的な指示を待つ。開始後は `origin/develop` の最新状態から専用ブランチと Worktree を作り、変更、Build、Test をその Worktree 内で行う。文書用 PR #23 の Worktree を実装に流用しない。
- 実装時には Apple 公式資料で API Availability と保存失敗の扱いを再確認し、公式事実と本プロジェクトの判断を分けて記録する。

## Review Focus

1. タイトルが空白だけの場合、作成できず、編集中も直前の有効値を失わない。Task 1 と 2 のテストで確認する。
2. 同名の Project と Note が別 ID として残り、Note が他 Project に表示されない。Task 1 と 2 のテストで確認する。
3. Project または Note を削除した後、選択詳細と再起動後の保存先に削除済み項目が残らない。Task 3 のテストで確認する。
4. 連続した本文入力とペーストで文字が欠落せず、Project を切り替えて戻っても全文が残る。Task 2 と 4 の UI Test で確認する。
5. 保存失敗時、成功表示や無言の画面終了を行わない。Task 0 の調査結果に基づく Task 4 のテストで確認する。

## File Map

| File | Responsibility |
|---|---|
| `ResearchNotebook/Project.swift`、`ResearchNotebook/Note.swift` | 永続化する属性、ID、所属 Relationship、連鎖削除。 |
| `ResearchNotebook/NotebookState.swift` | Phase 1 の値型配列。View 移行後に削除し、タイトル検証だけを必要最小限の共通関数へ移す。 |
| `ResearchNotebook/ResearchNotebookApp.swift` | 本番のローカル `ModelContainer` と UI Test の独立した保存先。 |
| `ResearchNotebook/ContentView.swift` | 3 列 Navigation、選択 ID の整合、保存失敗の表示。 |
| `ResearchNotebook/ProjectSidebarView.swift`、`ResearchNotebook/ProjectFormView.swift` | Project の取得、作成、編集、削除。 |
| `ResearchNotebook/NoteListView.swift`、`ResearchNotebook/NoteEditorView.swift` | 所属 Note の取得、作成、編集、単体削除。 |
| `ResearchNotebook/ValidatedTitleField.swift` | 必須タイトルの既存 UX を維持する。 |
| `ResearchNotebookTests/SwiftDataPersistenceTests.swift` | メモリ上のコンテナによる保存・再取得・Relationship・削除の振る舞い。 |
| `ResearchNotebookUITests/ResearchNotebookUITests.swift` | 再起動、自動保存、削除、連続入力の主要フロー。 |
| `docs/learning/phase-2.md`、`README.md` | 学習結果、確認範囲、永続化した操作の説明。 |

新規 Swift ファイルは既存の file-system-synchronized group に置く。既存のテスト用ファイルは、新モデルの振る舞いへ移した後に整理する。

---

### Task 0: 保存の失敗経路と対象 API を確定する

**Files:** Update this plan's Task 4 verification notes if the official API behavior requires it; no app source changes.

**Interfaces:** `ModelContext.autosaveEnabled`、`save()`、`didSave`、`ModelConfiguration` の iPadOS 17 での利用条件と、保存失敗を利用者へ伝える経路。

- [x] **Step 1: Apple 公式資料と Xcode 27 の SDK で採用 API の Availability を確認する。** `@Model`、`@Relationship`、`@Query`、`ModelContainer`、`ModelContext`、テスト用 `ModelConfiguration` を対象とする。
- [x] **Step 2: 自動保存の失敗を検出できる範囲を調べる。** `didSave` を失敗通知と取り違えない。確実に検出できる操作と、失敗を再現するテスト用保存先を記録する。
- [x] **Step 3: 承認済み Acceptance Criteria に足りる保存・エラー表示方法を Task 4 に具体化する。** 標準 API で満たせない場合は要求や ADR を暗黙に変えず、人間へ判断材料を提示してから実装する。

調査結果: SwiftData の暗黙の自動保存には公開された失敗通知が見当たらず、`didSave` は成功後のみ通知する。Task 4 では `mainContext.autosaveEnabled` を有効のまま使い、Project / Note の作成・編集・削除で有効な変更をモデルへ反映した直後に `hasChanges` を確認して `try modelContext.save()` を呼ぶ。これは利用者に保存操作を求めるものではない。失敗した場合はエラーを表示し、作成画面の完了や削除後の成功表示を行わない。編集中の未保存値を「保存済み」と表示しない。文字入力ごとの書き込み負荷は Task 4 の連続入力テストで確認する。

保存失敗テストには、書き込み可能なディスク保存先に既存データを作成してから `ModelConfiguration(url: ..., allowsSave: false)` で開き直す。iPadOS 17 Simulator で、この構成の `mainContext` は自動保存有効のまま `save()` がエラーを投げることを確認した。読み取り専用のメモリ内コンテナは構築段階で失敗したため、失敗再現には使わない。

### Task 1: 永続モデルと Relationship

**Files:** Create `ResearchNotebook/Project.swift`、`ResearchNotebook/Note.swift`、`ResearchNotebookTests/SwiftDataPersistenceTests.swift`

**Interfaces:** `@Model final class Project` と `@Model final class Note`。双方が `id: UUID`、`title: String`、`body: String` を持つ。`Project.notes` は `.cascade` と `Note.project` の inverse を持つ。共通の `isValidTitle(_ title: String) -> Bool` は前後の空白を除いた空文字を拒否する。View は作成・更新前に検証し、Note 作成時には所属 Project を必須とする。

- [x] **Step 1: Swift Testing に失敗するテストを書く。** `persistsProjectAndNoteRelationship` は保存後に別の `ModelContext` から ID、タイトル、本文、所属を再取得する。`allowsDuplicateTitlesWithDistinctIDs` は同名の二組を区別する。`rejectsBlankTitles` は `isValidTitle` が空白だけの入力を拒むことを確認する。
- [x] **Step 2: 選択した iPad Simulator の UDID で `scripts/test.sh` を実行し、新規テストの失敗を確認する。** 期待: 未実装の型と振る舞いに対応する失敗。
- [x] **Step 3: 二つの `@Model` とタイトル検証を実装する。** テストには `ModelConfiguration(isStoredInMemoryOnly: true)` を使い、実 Web サービスや利用者の保存先に依存しない。
- [x] **Step 4: 同じテストを再実行する。** 期待: Task 1 のテスト成功。`scripts/lint.sh` と `git diff --check` を確認し、Task 1 をコミットする。

### Task 2: 既存の作成・編集 UI を SwiftData に接続する

**Files:** Modify `ResearchNotebook/ResearchNotebookApp.swift`、`ContentView.swift`、`ProjectSidebarView.swift`、`ProjectFormView.swift`、`NoteListView.swift`、`NoteEditorView.swift`、`ValidatedTitleField.swift`、`ResearchNotebookUITests/ResearchNotebookUITests.swift`; Delete `ResearchNotebook/NotebookState.swift` after all callers migrate; update `ResearchNotebookTests/NotebookStateTests.swift` or delete it after equivalent tests move.

**Interfaces:** `ResearchNotebookApp` がローカル `ModelContainer` を提供する。Project 一覧は `@Query` から、Note 一覧は選択 Project の Relationship から表示する。選択は Project・Note の UUID で保持する。UI Test はテストごとに独立した保存先を指定し、同じテスト内の再起動では同じ保存先を使う。既存の accessibilityIdentifier と 3 列構造を維持する。

- [x] **Step 1: UI Test を更新する。** Project と Note の作成・編集、空白タイトルの拒否、同名項目の識別、Project 切替時の詳細解除を検証する。Phase 1 の「再起動で消える」期待だけを、Task 4 で復元を確認する期待へ変更する。
- [x] **Step 2: `scripts/test.sh` で新しい期待の失敗を確認する。** 期待: 永続化前の起動・再起動の振る舞いと一致しない。
- [x] **Step 3: 既存 View を永続モデルへ接続し、値型の配列と旧呼び出しを同じ変更で削除する。** UI Test の保存先も分離する。`ValidatedTitleField` は無効入力をモデルへ渡さない。`NoteBodyEditor` の局所的な `equatable()` は無条件に移植せず、連続入力で必要か確認する。
- [x] **Step 4: UI Test と Task 1 のテストを再実行する。** 期待: 作成・編集・選択の正常系と異常系が成功。`scripts/build.sh`、`scripts/lint.sh`、`git diff --check` を確認し、Task 2 をコミットする。

### Task 3: Note 単体削除と Project の連鎖削除

**Files:** Modify `ResearchNotebook/NoteEditorView.swift`、`ProjectFormView.swift`、`ContentView.swift`、`ResearchNotebookTests/SwiftDataPersistenceTests.swift`、`ResearchNotebookUITests/ResearchNotebookUITests.swift`

**Interfaces:** Note 削除は `ModelContext.delete(_:)` を使う。Project 削除は `Project.notes` の `.cascade` を使い、Note の手動全件削除を重ねない。削除後、無効な選択 ID を解除する。

- [x] **Step 1: 失敗するテストを書く。** Note 単体の削除・キャンセル・他項目の保持、Project 削除後の所属 Note の不在、選択詳細の解除を検証する。保存後に別コンテキストから再取得して削除を確認する。iPadOS 17 Simulator のメモリ内コンテナでは `delete(_:)` 後に子 Note が残った一方、`delete(model:where:)` では削除された。Task 3 で本番と同じディスク保存先でも再確認する。
- [x] **Step 2: `scripts/test.sh` で失敗を確認する。** 期待: Note 単体削除の操作が存在しない。
- [x] **Step 3: 標準の破壊的操作と確認表示で削除を実装する。** Project 削除時は所属 Note も失うことを既存の確認文で知らせる。
- [x] **Step 4: 同じテスト、`scripts/build.sh`、`scripts/lint.sh`、`git diff --check` を実行する。** 期待: 削除と既存フローが成功。Task 3 をコミットする。

### Task 4: 自動保存、保存失敗、再起動

**Files:** Modify `ResearchNotebook/ContentView.swift` と必要な編集 View、`ResearchNotebook/ResearchNotebookApp.swift`、`ResearchNotebookTests/SwiftDataPersistenceTests.swift`、`ResearchNotebookUITests/ResearchNotebookUITests.swift`

**Interfaces:** Task 0 で確認した保存・エラー通知経路と、Task 2 の独立した UI Test 保存先を使う。

- [x] **Step 1: 失敗するテストを書く。** 保存ボタンなしで Project・Note の編集結果が再起動後も残ること、連続本文入力・ペーストの全文が残ること、保存失敗時に失敗が分かり成功表示しないことを検証する。失敗系には Task 0 の読み取り専用ディスク保存先を使い、`save()` のエラー後に既存データが残り、新規データが保存されないことも確認する。
- [x] **Step 2: `scripts/test.sh` で失敗を確認する。** 期待: 再起動または失敗表示の新しい期待に対応する失敗。
- [x] **Step 3: Task 0 で確定した自動保存と失敗表示を実装する。** 保存ボタンは追加しない。各有効変更の反映直後に `hasChanges` を確認し、`save()` のエラーを捕捉して表示する。失敗時に成功を示す画面遷移や表示を行わない。読み取り専用ディスク保存先で失敗を再現する。
- [x] **Step 4: 同じテストを再実行し、`scripts/build.sh`、`scripts/lint.sh`、`git diff --check` を確認する。** 期待: 正常系・失敗系が成功。Task 4 をコミットする。

### Task 5: iPad の実操作、学習ログ、完了確認

**Files:** Create `docs/learning/phase-2.md`; Modify `README.md`、必要なら該当 View とテスト

**Interfaces:** Task 1〜4 の完成したアプリと既存の Definition of Done。

- [ ] **Step 1: iPad の全画面と狭い幅で作成・編集・削除・戻る操作を確認する。** Dark Mode、最大側の Dynamic Type、VoiceOver、キーボードで主要操作と保存失敗の説明を確認する。確認できない項目は Done と扱わない。
- [ ] **Step 2: `README.md` と Phase 2 学習ログを更新する。** `@Model`、Relationship、コンテナ、コンテキスト、`@Query`、Migration の考え方、Apple 公式資料の確認日、実測結果と未確認点を記録する。
- [ ] **Step 3: `scripts/build.sh`、`scripts/lint.sh`、`SIMULATOR_UDID=<利用可能なiPad UDID> scripts/test.sh`、`git diff --check` を実行する。** 期待: Build・全テスト・Lint 成功、新規警告なし。
- [ ] **Step 4: 全 Acceptance Criteria と Definition of Done を証拠に照らして判定する。** 満たせない項目は理由と残課題を記録する。満たした場合に作業ブランチを push し、日本語の `develop` 宛て PR を作成する。

## Self-Review

- 各 Acceptance Criterion は Task 1〜4 のテストと Task 5 の実操作に対応する。
- Task 1 の永続モデル追加後も既存アプリは動く。Task 2 で旧状態と呼び出しをまとめて削除し、二重のデータ表現を残さない。
- 保存失敗の観測方法を Task 0 で確定するまでは、Task 4 の成否を推測しない。
- この計画書の作成では、アプリの実装・Build・Test を実行しない。
