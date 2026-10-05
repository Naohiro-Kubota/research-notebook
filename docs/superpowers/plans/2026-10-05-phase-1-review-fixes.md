# Phase 1 レビュー指摘修正 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** UI テストの英語メニュー名依存を除き、Project / Note の ID 一意性と Project 削除後の Note 詳細消去を検証する。

**Architecture:** 既存の `NotebookState` と XCTest UI Test を局所的に修正する。状態管理や Navigation の構造は変更しない。

**Tech Stack:** Swift 6、SwiftUI、Swift Testing、XCTest UI Test、iPadOS 17 以降。

**Spec:** `docs/requirements/phase-1-notebook-basic-ui.md`、2026-10-05 のユーザーによる3項目の修正指示。

## Global Constraints

- 専用 Worktree `codex/phase1-review-fixes` で作業し、`origin/develop` の `78c03bb` を起点にする。
- 新規外部依存なし。`docs/adr/0001-native-swiftui-data-flow.md` と `docs/adr/0002-testing-strategy.md` に従う。
- UI テストのシステムメニュー項目名を参照しない。困難な場合に限りテスト環境の言語を固定する。
- 同じ Project / Note タイトルは許す。同じ種類の重複 UUID は拒否する。
- Project 削除で所属 Note と選択詳細が消えることを UI Test で確認する。

## Completion Evidence（2026-10-05）

- Task 1: ⌘V / ⌘A は iPadOS 17.2 Simulator で成立しなかった。タイトル2テストは削除キーと `replaceText` で最後の有効値 `U` の保持・復元を検証し、`Select All` 依存を除去した。ペーストだけ `-AppleLanguages (en)` / `-AppleLocale en_US` を固定する代替を採用。非英語 Simulator の比較検証は未実施。最終対象3テスト成功、コミット `0754c0c`。
- Task 2: 重複 UUID 拒否2テストの期待した失敗を確認後、追加前の guard を実装。既存データ・選択保持と種類をまたぐ同一 UUID 許可を確認。対象モデル9テスト成功、コミット `3d96b1d`。
- Task 3: Note 作成・選択後の親 Project 削除で、Project / Note 行とタイトル・本文欄の不在、詳細の空状態を確認。一時変異で残存詳細の検出を確認し、変異を撤去。対象テスト成功、コミット `10e7487`。
- Task 3 の全実行で見つかった `Select All` の不安定さは Task 1 の修正で解消。最終全実行は Swift Testing 10件 + UI Test 9件、失敗0。Build / Lint 成功、新規 Swift 警告なし（既存 App Intents metadata 警告のみ）。構造変更がないため新規 ADR は不要。

## Review Focus

- タイトル検証は `Select All` に依存しない。ペーストはキー入力が成立しない実測により英語起動言語へ固定する代替を採用する（非英語 Simulator での成功は未検証）。
- 重複 ID の拒否は状態を変更せず、既存の Project / Note 選択を保つ。
- Project ID と Note ID は別の配列なので、種類をまたぐ同一 UUID は妨げない。
- 削除 UI Test は Note 作成後に Project を削除し、Note 行と詳細の両方が消えることを確認する。
- 既存の非永続化、タイトル検証、入力即時反映のテストを維持する。

### Task 1: UI テストのメニュー名依存を解消

**Files:** `ResearchNotebookUITests/ResearchNotebookUITests.swift`

- [x] `Select All` の2箇所を既存 `replaceText` に置き換え、無効タイトルの説明・復元の検証を維持する。
- [x] `Paste` メニュー名を使わずにクリップボードの複数行本文を入力し、Project 切替後の全文一致を維持する。まず ⌘V のキー入力を試し、実環境で成立しない場合だけテスト言語固定の代替案を採用する。
- [x] 対象 UI Test と全テスト、Lint を実行し、差分をコミットする。

### Task 2: 重複 UUID を拒否

**Files:** `ResearchNotebook/NotebookState.swift`、`ResearchNotebookTests/NotebookStateTests.swift`

- [x] `addProject(id:title:body:)` と `addNote(id:projectID:title:body:)` の重複 ID を拒否し、既存値・選択が変わらないことを確認する失敗テストを書く。
- [x] テストの期待する失敗を確認してから、各追加操作に最小限の重複検査を実装する。
- [x] 対象 Unit Test と全テスト、Lint を実行し、差分をコミットする。

### Task 3: Project 削除時の Note 消去を UI で検証

**Files:** `ResearchNotebookUITests/ResearchNotebookUITests.swift`

- [x] 既存の Project 削除 UI Test で、事前に Note を作成・選択する。
- [x] 削除後の Project 行、Note 行、Note 詳細の不在を検証する。必要ならテストがカスケード処理の欠落を検出できることを一時的な変異で確認し、変異を残さない。
- [x] 対象 UI Test と全テスト、Build、Lint を実行し、差分をコミットする。

## Self-Review

- 3つのユーザー指示をそれぞれ1つの Task に対応させた。
- UI Test の自然言語メニュー名依存の解消とモデルの入力検証を別々にレビューできる。
- Task 3 は既存のカスケード処理の検証強化で、プロダクトコード変更を要求しない。
