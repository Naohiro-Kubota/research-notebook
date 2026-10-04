# Phase 1 Notebook 基本 UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Project と Note の一時データを 3 列で閲覧・編集できる iPad アプリにする。

**Architecture:** `ContentView` が値型の `NotebookState` を `@State` で所有し、必要な子 View に Binding を渡す。Project 一覧、Note 一覧、Note 編集を `NavigationSplitView` の sidebar、content、detail に置く。永続化は Phase 2 に残す。

**Tech Stack:** Xcode 27.0 同梱の Swift 6.4 コンパイラ、Swift 6 言語モード、SwiftUI、Swift Testing、XCTest UI Test、iPadOS 17 以降。外部依存なし。

**Spec:** `docs/requirements/phase-1-notebook-basic-ui.md`、`docs/adr/0004-three-column-notebook-navigation.md`

## Global Constraints

- 対象は iPad、Deployment Target は iPadOS 17、Bundle Identifier は `com.tabfav`。
- Swift 言語モードは Xcode 27.0 で利用可能な最新の Swift 6 を使う。人間が 2026-10-04 に、iPadOS 17 を維持できることを条件として決定した。[Apple の Xcode 対応表](https://developer.apple.com/xcode/system-requirements)で、Xcode 27 は iPadOS 17 を Deployment Target にでき、Swift 6.4 コンパイラと Swift 6 言語モードを提供することを同日に確認した。
- Project と Note は `title: String` と `body: String` を持つ。前後の空白を除いたタイトルが空なら無効。本文は空でもよい。
- Phase 1 ではデータをメモリ上に保持し、再起動後の復元と保存操作は設けない。
- Note 作成は対象。Note 単体削除と SwiftData は Phase 2。
- Project 削除で所属 Note も削除し、選択を整合させる。
- 有効なタイトル変更と本文入力は画面へ即時反映する。無効なタイトル編集中は直前の有効な値を保持する。
- ADR-0001 の SwiftUI データフロー、ADR-0002 のテスト方式、ADR-0004 の 3 列 Navigation に従う。
- ファイル変更、Build、Test は現在の専用 Worktree 内で行う。`scripts/build.sh`、`scripts/lint.sh`、`scripts/test.sh` を使う。
- Test 前に `xcrun simctl list devices available` で利用可能な iPad の UDID を調べ、作業端末の `RESEARCH_NOTEBOOK_SIMULATOR_UDID` に設定する。

## Review Focus

1. 空白だけのタイトルでは作成できず、編集時は直前の有効なタイトルが残る。Task 1 のモデルテストと Task 2・3 の UI テストで確認する。
2. 同名の Project や Note が複数あっても ID で別々に選択・編集できる。Task 1 のテストで確認する。
3. Project 切替時に前の Project の Note が詳細に残らない。Task 1 のテストと Task 3 の UI テストで確認する。
4. Project 削除で所属 Note と選択が消え、他の Project と Note は残る。Task 1 のテストと Task 2 の UI テストで確認する。
5. 狭いウインドウで Project → Note → 編集と戻る経路が失われない。Task 4 の実画面確認で検証する。

## File Map

| File | Responsibility |
|---|---|
| `ResearchNotebook/NotebookState.swift` | Project、Note の値型、ID、タイトル検証、一覧操作、選択整合性。 |
| `ResearchNotebook/ContentView.swift` | `@State` の所有と 3 列 `NavigationSplitView` の接続。 |
| `ResearchNotebook/ProjectSidebarView.swift` | Project 一覧、選択、作成、編集、削除確認と空状態。 |
| `ResearchNotebook/ProjectFormView.swift` | 既存 Project のタイトル・本文編集。作成用の入力は sidebar の Sheet が所有する。 |
| `ResearchNotebook/NoteListView.swift` | 選択 Project の Note 一覧、作成、空状態。 |
| `ResearchNotebook/NoteEditorView.swift` | 選択 Note のタイトル・本文編集。 |
| `ResearchNotebook/ValidatedTitleField.swift` | 有効なタイトルだけを Binding に反映し、無効入力を説明・復元する入力欄。 |
| `ResearchNotebookTests/NotebookStateTests.swift` | 状態操作の振る舞いを Swift Testing で検証。 |
| `ResearchNotebookUITests/ResearchNotebookUITests.swift` | 起動と主要な Project／Note 操作を XCTest で検証。 |
| `docs/learning/phase-1.md` | 学習内容、Apple 公式資料、検証結果、未確認点。 |
| `README.md` | Phase 1 の操作とデータが一時的であることを説明。 |

新規 Swift ファイルは既存の file-system-synchronized group に配置する。Xcode Project の設定変更が必要かは Build で確認し、必要な場合のみ Project ファイルを編集する。

---

### Task 0: Swift 6 言語モードへの設定変更

**Files:** Modify `ResearchNotebook.xcodeproj/project.pbxproj`; Modify `ResearchNotebook/`、`ResearchNotebookTests/`、`ResearchNotebookUITests/` の既存 Swift ファイルは Swift 6 診断の解消が必要な場合のみ

**Interfaces:** アプリ、Unit Test、UI Test の 3 Target すべてで Debug・Release の `SWIFT_VERSION = 6.0` を設定する。Deployment Target `17.0` と Bundle Identifier `com.tabfav` は維持する。

- [ ] **Step 1: 現行設定と利用可能なツールチェーンを確認する。** `xcrun swift --version`、`xcodebuild -version`、`rg 'SWIFT_VERSION|IPHONEOS_DEPLOYMENT_TARGET|PRODUCT_BUNDLE_IDENTIFIER' ResearchNotebook.xcodeproj/project.pbxproj` を実行して記録する。
- [ ] **Step 2: 6 箇所の `SWIFT_VERSION` を `6.0` に変更する。** Swift 6 のコンパイル診断が出た場合は原因を確認し、既存コードの意図を保つ最小の修正だけを行う。
- [ ] **Step 3: `scripts/build.sh`、`SIMULATOR_UDID="$RESEARCH_NOTEBOOK_SIMULATOR_UDID" scripts/test.sh`、`scripts/lint.sh` を実行する。** 期待: Build、既存 Unit/UI Test、Lint が成功し、新規警告なし。生成アプリが iPadOS 17 を対象とする設定を確認する。
- [ ] **Step 4: `git diff --check` を実行し、設定変更と必要な診断修正をコミットする。**

### Task 1: 一時データと操作

**Files:** Create `ResearchNotebook/NotebookState.swift`、`ResearchNotebookTests/NotebookStateTests.swift`

**Interfaces:**

- `struct NotebookProject: Identifiable, Equatable { let id: UUID; var title: String; var body: String }`
- `struct NotebookNote: Identifiable, Equatable { let id: UUID; let projectID: UUID; var title: String; var body: String }`
- `struct NotebookState { private(set) var projects: [NotebookProject] = []; private(set) var notes: [NotebookNote] = []; private(set) var selectedProjectID: UUID? = nil; private(set) var selectedNoteID: UUID? = nil }`
- `static func isValidTitle(_ title: String) -> Bool`
- `mutating func addProject(id: UUID = UUID(), title: String, body: String = "") -> UUID?`
- `mutating func addNote(id: UUID = UUID(), projectID: UUID, title: String, body: String = "") -> UUID?`
- `mutating func updateProjectTitle(id: UUID, title: String) -> Bool`、`updateNoteTitle(id:title:) -> Bool`
- `mutating func updateProjectBody(id: UUID, body: String)`、`updateNoteBody(id: UUID, body: String)`
- `mutating func selectProject(_ id: UUID?)`、`selectNote(_ id: UUID?)`、`removeProject(id: UUID)`
- `func notes(in projectID: UUID) -> [NotebookNote]`

- [ ] **Step 1: 失敗する Swift Testing を書く。** `rejectsBlankTitles` で `#expect(!NotebookState.isValidTitle("  "))`、`#expect(state.addProject(title: "  ") == nil)`、有効なタイトルと空本文での作成成功を検証する。`keepsDistinctIDsForDuplicateTitles`、`rejectsNoteForMissingProject`、`updatesOnlyValidTitles`、`clearsNoteSelectionWhenProjectChanges`、`removesOnlyDeletedProjectsNotes` で、各名称の振る舞いと本文更新を `#expect` する。
- [ ] **Step 2: `SIMULATOR_UDID="$RESEARCH_NOTEBOOK_SIMULATOR_UDID" scripts/test.sh` で失敗を確認する。** 期待: 未実装の型・操作に対応するテスト失敗。
- [ ] **Step 3: `NotebookState.swift` を実装する。** 一時データは値型で持ち、ID で関連付ける。`addProject` は新 Project を選択し、`addNote` は所属 Project と新 Note を選択する。`selectProject` は所属しない Note の選択を解除し、`selectNote` は現在の Project に属する Note だけを選択する。`removeProject` は所属 Note と該当する選択を消し、他 Project の選択は保持する。
- [ ] **Step 4: 同じ Test を再実行する。** 期待: Task 1 の新規テストと既存テストが成功。
- [ ] **Step 5: `scripts/lint.sh` と `git diff --check` を実行して Task 1 をコミットする。**

### Task 2: Project 一覧と操作

**Files:** Modify `ResearchNotebook/ContentView.swift`、`ResearchNotebookUITests/ResearchNotebookUITests.swift`; Create `ResearchNotebook/ProjectSidebarView.swift`、`ResearchNotebook/ProjectFormView.swift`、`ResearchNotebook/ValidatedTitleField.swift`

**Interfaces:** `ContentView` は `@State private var notebook = NotebookState()` を所有する。`ProjectSidebarView` は `@Binding var notebook: NotebookState` を受け、作成 Sheet の入力を所有する。`ProjectFormView` は `@Binding var notebook: NotebookState` と `projectID: UUID` を受ける。`ValidatedTitleField` は `Binding<String>`、ラベル、Accessibility ID を受け、有効入力のみモデルに渡す。

- [ ] **Step 1: 失敗する UI テストを書く。** `testProjectCreationAndEditing` で起動時の `project-empty`、空白タイトルで作成ボタンが無効、有効タイトルで作成後の行、タイトルと本文の編集反映、無効なタイトル編集後に直前の有効値が残ることを `XCTAssert` する。`testProjectDeletionCanBeCancelled` と `testProjectDeletionRemovesRow` でキャンセル・確定を別々に確認する。同名 Project は 2 行として表示されることを確認し、従来の静的 `app-title` テストは新しい起動画面に合わせて更新する。
- [ ] **Step 2: `SIMULATOR_UDID="$RESEARCH_NOTEBOOK_SIMULATOR_UDID" scripts/test.sh` で失敗を確認する。** 期待: 新しい操作を表す UI 要素が未存在。
- [ ] **Step 3: `ContentView` の 3 列骨格と Project の UI を実装する。** sidebar に Project 一覧と選択を置き、content/detail は選択に応じた意味のある空状態から始める。作成・編集・削除は標準の SwiftUI コントロールを使い、削除時には所属 Note も消えることを確認画面に示す。UI Test 用 Accessibility ID は `project-empty`、`project-add`、`project-title-input`、`project-body-input`、`project-delete`、`project-row-<ID>` とする。
- [ ] **Step 4: 同じ Test を再実行する。** 期待: Task 2 の UI テストと Task 1 の Unit Test が成功。
- [ ] **Step 5: `scripts/build.sh`、`scripts/lint.sh`、`git diff --check` を実行して Task 2 をコミットする。**

### Task 3: Note 一覧と編集

**Files:** Create `ResearchNotebook/NoteListView.swift`、`ResearchNotebook/NoteEditorView.swift`; Modify `ResearchNotebook/ContentView.swift`、`ResearchNotebookUITests/ResearchNotebookUITests.swift`

**Interfaces:** `NoteListView` と `NoteEditorView` は `@Binding var notebook: NotebookState` を受ける。`NoteListView` は Task 1 の `notes(in:)` と `addNote(id:projectID:title:body:)` を使う。`NoteEditorView` は Task 1 の更新操作と Task 2 の `ValidatedTitleField` を使う。

- [ ] **Step 1: 失敗する UI テストを書く。** `testNoteCreationAndLiveEditing` で `note-empty`、空白タイトルでは作成不可、作成後の行と編集画面、タイトル・本文の即時反映、無効なタイトル編集後の有効値保持を `XCTAssert` する。`testSwitchingProjectsClearsNoteDetail` で別 Project に切り替えたときの詳細解除を確認する。Note 単体の削除操作が表示されないことも確認する。
- [ ] **Step 2: `SIMULATOR_UDID="$RESEARCH_NOTEBOOK_SIMULATOR_UDID" scripts/test.sh` で失敗を確認する。** 期待: Note 一覧または編集操作が未存在。
- [ ] **Step 3: Note 一覧と編集 UI を実装する。** content に選択 Project の Note、detail に選択 Note のタイトルと本文を表示する。ID は `note-empty`、`note-add`、`note-title-input`、`note-body-input`、`note-row-<ID>` とする。本文は `TextEditor` を使う。
- [ ] **Step 4: 同じ Test を再実行する。** 期待: Project／Note の主要 UI フローと Unit Test が成功。
- [ ] **Step 5: `scripts/build.sh`、`scripts/lint.sh`、`git diff --check` を実行して Task 3 をコミットする。**

### Task 4: iPad での検証と文書化

**Files:** Create `docs/learning/phase-1.md`; Modify `README.md`、必要なら UI テストと該当 View

**Interfaces:** Task 1–3 の完成したアプリと `scripts/` の既存コマンドを検証対象とする。

- [ ] **Step 1: iPad Simulator で全画面と狭いウインドウ幅の Project → Note → 編集、戻る操作、削除後の空状態、アプリ再起動後にデータが復元されないことを確認する。** 幅変更の操作が自動化できない場合は人間による確認結果を得て記録する。確認できなければ DoD 未達と明記する。
- [ ] **Step 2: Dark Mode、最大側の Dynamic Type、VoiceOver、キーボードで主要操作を確認する。** 色だけに依存する状態表示や見切れ、到達不能な操作があれば該当 View と必要なテストを修正する。
- [ ] **Step 3: `README.md` に Phase 1 の操作と再起動でデータが消えることを記載し、`docs/learning/phase-1.md` に学習概念、Apple 公式資料と確認日、公式事実と設計判断、検証結果、理解しづらかった点、次 Phase の課題を記録する。**
- [ ] **Step 4: `scripts/build.sh`、`scripts/lint.sh`、`SIMULATOR_UDID="$RESEARCH_NOTEBOOK_SIMULATOR_UDID" scripts/test.sh`、`git diff --check` を実行する。** 期待: Build、Lint、Unit/UI Test 成功、新規コンパイラ警告なし。
- [ ] **Step 5: 要求仕様と Definition of Done の各項目を照合し、Task 4 をコミットする。** 完了後、作業ブランチを push して `develop` 向け日本語 PR を作り、Pull Request CI を確認する。

## Self-Review

- Acceptance Criteria は Task 1–4 のテストと画面確認に対応する。再起動後の非復元は Task 4 の実操作でも確認する。
- UI Test 用 ID は実装時に固定し、表示文言が変わっても主要操作を特定できるようにする。
- `NavigationSplitView` の列表示は OS に任せる。実画面で問題が見つかった場合だけ ADR-0004 に沿って制御を追加する。
- Xcode の file-system-synchronized group が新規 Swift ファイルを認識するか Build で確認する。
