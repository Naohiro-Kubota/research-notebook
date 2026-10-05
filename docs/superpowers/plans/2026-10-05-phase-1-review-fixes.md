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

## Review Focus

- 日本語 UI 環境でも `Select All` / `Paste` 文字列への依存なしにテストできる。
- 重複 ID の拒否は状態を変更せず、既存の Project / Note 選択を保つ。
- Project ID と Note ID は別の配列なので、種類をまたぐ同一 UUID は妨げない。
- 削除 UI Test は Note 作成後に Project を削除し、Note 行と詳細の両方が消えることを確認する。
- 既存の非永続化、タイトル検証、入力即時反映のテストを維持する。

### Task 1: UI テストのメニュー名依存を解消

**Files:** `ResearchNotebookUITests/ResearchNotebookUITests.swift`

- [ ] `Select All` の2箇所を既存 `replaceText` に置き換え、無効タイトルの説明・復元の検証を維持する。
- [ ] `Paste` メニュー名を使わずにクリップボードの複数行本文を入力し、Project 切替後の全文一致を維持する。まず ⌘V のキー入力を試し、実環境で成立しない場合だけテスト言語固定の代替案を採用する。
- [ ] 対象 UI Test と全テスト、Lint を実行し、差分をコミットする。

### Task 2: 重複 UUID を拒否

**Files:** `ResearchNotebook/NotebookState.swift`、`ResearchNotebookTests/NotebookStateTests.swift`

- [ ] `addProject(id:title:body:)` と `addNote(id:projectID:title:body:)` の重複 ID を拒否し、既存値・選択が変わらないことを確認する失敗テストを書く。
- [ ] テストの期待する失敗を確認してから、各追加操作に最小限の重複検査を実装する。
- [ ] 対象 Unit Test と全テスト、Lint を実行し、差分をコミットする。

### Task 3: Project 削除時の Note 消去を UI で検証

**Files:** `ResearchNotebookUITests/ResearchNotebookUITests.swift`

- [ ] 既存の Project 削除 UI Test で、事前に Note を作成・選択する。
- [ ] 削除後の Project 行、Note 行、Note 詳細の不在を検証する。必要ならテストがカスケード処理の欠落を検出できることを一時的な変異で確認し、変異を残さない。
- [ ] 対象 UI Test と全テスト、Build、Lint を実行し、差分をコミットする。

## Self-Review

- 3つのユーザー指示をそれぞれ1つの Task に対応させた。
- UI Test の自然言語メニュー名依存の解消とモデルの入力検証を別々にレビューできる。
- Task 3 は既存のカスケード処理の検証強化で、プロダクトコード変更を要求しない。
