# Observation による UI 状態管理 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Phase 3 の検索語、タグ条件、Project・Note 選択をウインドウ単位の `@Observable` 状態で所有し、既存の表示と永続データを維持する。

**Architecture:** `ContentView` が `@State` で一つの `NotebookUIState` を所有し、子 View へ渡す。SwiftData の Project・Note・Tag は従来どおり `@Model`／`@Query` で扱い、検索結果はモデルと条件から導出する。選択解除に必要な表示対象 ID は View から状態型へ渡す。

**Tech Stack:** Swift 6、SwiftUI Observation、SwiftData、Swift Testing、XCTest。Deployment Target は iPadOS 17。新規外部依存なし。

**Spec:** [ADR-0007](../../adr/0007-observation-ui-state.md)、[Phase 3 要求](../../requirements/phase-3-app-state-and-search.md)、[ADR-0006](../../adr/0006-phase-3-tags-and-search-state.md)。

## Global Constraints

- 実装開始には人間の明示的な指示が必要。計画の承認だけを実装開始指示と扱わない。
- 開始時に最新の `origin/develop` から専用ブランチと Git Worktree を作り、変更・Build・Test はその Worktree 内で行う。
- Project 内検索、検索語と単一タグの AND 条件、Project 切替時の条件保持、詳細選択解除を維持する。
- SwiftData スキーマ、永続化方式、Navigation 構造、外部依存、非同期処理を変更しない。必要になったら実装を止めて人間に報告する。
- 自動テストは Swift Testing と XCTest。Simulator の手動操作を伴う確認は人間だけが行い、AI は代行しない。
- 各 Task は関連テスト・文書更新・コミットで区切り、Task 3 で全体を独立レビューして `develop` 向けの日本語 PR とする。Phase 3 の未達 DoD を完了扱いにしない。

## Review Focus

- Project 切替後も検索語と選択タグが残り、旧 Project の Note 選択は解除されること（Task 1 の状態テスト、Task 2 の既存 UI Test）。
- 検索語とタグ条件で Note が隠れたときだけ選択解除し、Note のデータは変えないこと（Task 1 の状態テスト、Task 2 の既存 UI Test）。
- Note・Project 削除後の選択解除と空表示を維持すること（Task 2 の既存 UI Test）。
- 別のウインドウに対応する状態インスタンス間で検索語と選択 ID が共有されないこと（Task 1 の状態テスト）。
- 保存失敗と旧ストアからのデータ保持が状態移行で後退しないこと（Task 2 の既存 Swift Testing／XCTest）。

---

### Task 1: Observable な一時状態と遷移

**Files:**
- Create: `ResearchNotebook/NotebookUIState.swift`
- Create: `ResearchNotebookTests/NotebookUIStateTests.swift`

**Interfaces:**
- Produces: `@MainActor @Observable final class NotebookUIState`。可変プロパティ `selectedProjectID: UUID?`、`selectedNoteID: UUID?`、`searchText: String`、`selectedTagID: UUID?`。初期値はそれぞれ `nil`、`nil`、`""`、`nil`。
- Produces: `func reconcileSelection(visibleNoteIDs: Set<UUID>)`。選択 ID が集合にない場合だけ `selectedNoteID` を `nil` にする。他の三つの状態は変更しない。SwiftData 型を引数・保存プロパティにしない。

- [x] **Step 1:** Swift Testing に、初期値、表示対象に残る／外れる Note、空集合、Project 切替を模した別集合、二つの状態インスタンスの独立性を検証するテストを書く。検索語とタグ ID が `reconcileSelection` で維持されることも確認する。
- [x] **Step 2:** 利用可能な iPad Simulator UDID を `xcrun simctl list devices available` で選び、`SIMULATOR_UDID=<UDID> scripts/test.sh` を実行する。新テストが型未定義で失敗することを確認する。Simulator の画面は操作しない。
- [x] **Step 3:** `NotebookUIState` と `reconcileSelection(visibleNoteIDs:)` を最小限で実装する。ViewModel、Repository、Protocol、SwiftData モデルの複製は追加しない。
- [x] **Step 4:** 同じ `scripts/test.sh` と `scripts/build.sh`、`scripts/lint.sh` を実行し、新テストの成功と既存テストの後退がないことを確認する。
- [x] **Step 5:** `docs/learning/phase-3.md` に `@Observable`、`@State`、SwiftData `@Model` の役割と Apple 公式資料を記録し、変更をコミットする。

### Task 2: View と Observable 状態の接続

**Files:**
- Modify: `ResearchNotebook/ContentView.swift`
- Modify: `ResearchNotebook/ProjectSidebarView.swift`
- Modify: `ResearchNotebook/NoteListView.swift`
- Test: `ResearchNotebookUITests/ResearchNotebookUITests.swift`（既存テストで不足が判明した振る舞いだけ追加）

**Interfaces:**
- Consumes: Task 1 の `NotebookUIState` と `reconcileSelection(visibleNoteIDs:)`。
- Produces: `ContentView` が `@State private var uiState = NotebookUIState()` を所有する。子 View は同じ `NotebookUIState` を受け取り、`List(selection:)` と `.searchable(text:)` に必要な Binding を `@Bindable` から作る。

- [x] **Step 1:** 既存 XCTest UI Test の Project 切替、検索とタグの AND 条件、選択解除、削除、保存失敗を確認し、不足する回帰だけテストを追加する。追加した場合は `SIMULATOR_UDID=<UDID> scripts/test.sh` で変更前に失敗を確認する。
- [x] **Step 2:** `ContentView` の四つの個別 `@State` を `uiState` に置き換える。`columnVisibility` と `editedProject` は View 局所の `@State` に残し、検索結果と選択 Note は従来どおり SwiftData モデルから導出する。
- [x] **Step 3:** `ProjectSidebarView` と `NoteListView` に同じ `uiState` を渡し、選択・作成・削除の読み書きを接続する。Binding が必要な位置で `@Bindable` を使用し、両 View に状態のコピーを作らない。
- [x] **Step 4:** Project 選択 ID と表示対象 Note ID の変化を受け、`ContentView` から `uiState.reconcileSelection(visibleNoteIDs:)` を呼ぶ。列表示、詳細の空状態、検索語・タグ条件の保持を維持する。
- [x] **Step 5:** `scripts/build.sh`、`scripts/lint.sh`、`SIMULATOR_UDID=<UDID> scripts/test.sh` を実行し、Swift Testing と XCTest の件数・失敗数・新規警告を記録する。Simulator の手動操作はしない。
- [x] **Step 6:** `docs/learning/phase-3.md` に所有者と Binding 経路、状態移行前後で維持した動作を記録し、変更をコミットする。

### Task 3: 全体照合と完了記録

**Files:**
- Modify: `docs/learning/phase-3.md`
- Modify: `docs/superpowers/plans/2026-10-06-observation-ui-state.md`
- Modify: `docs/requirements/phase-3-app-state-and-search.md`（人間の確認で DoD が満たされた場合のみ）

**Interfaces:**
- Consumes: Task 1・2 の実装とテスト結果。
- Produces: ADR-0007、要求、DoD に対する結果と未確認項目の記録。

- [x] **Step 1:** ADR-0007 の四状態、ウインドウ単位の所有、SwiftData との分離、既存の検索・タグ・選択動作を差分とテストで照合する。
- [x] **Step 2:** `scripts/build.sh`、`scripts/lint.sh`、`SIMULATOR_UDID=<UDID> scripts/test.sh`、`git diff --check` を実行する。Swift Testing と XCTest の結果を分けて記録する。
- [x] **Step 3:** [Definition of Done](../../development/definition-of-done.md)を項目ごとに確認する。可変幅、Dark Mode、Dynamic Type、VoiceOver、キーボードの Simulator 手動操作が必要な項目は人間の報告だけを根拠とし、未報告なら未達と記録する。
- [ ] **Step 4:** 学習ログと本計画を更新し、必要な場合だけ要求の最後の Acceptance Criteria を更新する。独立レビューを受け、指摘を解決してコミットする。
- [ ] **Step 5:** ブランチを push し、日本語タイトル・本文で `develop` 向け PR を作成する。DoD 未達項目があれば PR に明記する。

## 停止条件

- ADR-0007 の四状態以外へ所有変更を広げる、Project・Note・Tag のスキーマを変更する、Navigation 構造を変更する、または承認済み要求の動作を変える必要が出た場合は実装を止め、人間の判断を受ける。
- Simulator の手動確認結果が得られない場合は、自動テスト成功と区別し、Phase 3 の DoD を完了と報告しない。

## 実行状況（2026-10-06）

- Task 1: `e86982e`。失敗先行テスト、状態型、Build・Lint・全自動テスト、学習ログ、独立レビュー済み。
- Task 2: `4e13597`。既存 UI Test の回帰範囲を確認し、追加不要と判断。View 接続、Build・Lint・全自動テストの結果確認、学習ログ、独立レビュー済み。
- Task 3 Step 3 は DoD の照合・未達記録が済んだことを示し、DoD 達成を意味しない。可変幅の検索欄以外の主要 UI、Dark Mode、Dynamic Type、VoiceOver 音声、外部キーボードの人間確認が未報告。Phase 3 要求の最後の Acceptance Criteria は未完のまま維持する。
- Task 3 Step 4 の独立レビューと Step 5 の push・PR は最終担当者が実施する。
- Task 3 Step 2: Build・Lint・全自動テスト・`git diff --check` 成功。Swift Testing 24 件、XCTest UI Test 20 件、失敗 0。パラメータ展開を含む 48 回。詳細と未達 DoD は [学習ログ](../../learning/phase-3.md)に記録。
