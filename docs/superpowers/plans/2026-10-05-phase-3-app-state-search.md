# Phase 3 アプリ状態と検索の実装計画

> 実装は人間の明示的な開始指示を受けてから行う。開始後は `superpowers:executing-plans` に従い、下記の Task を順に検証する。

**Goal:** Note に共有タグを付け、選択中の Project 内を検索・絞り込み、表示と選択を一致させる。

**Architecture:** Project と Note は既存の SwiftData モデルを使い、共有 `Tag` モデルを追加する。検索語、選択タグ、選択 ID は `ContentView` の一時状態とし、選択中 Project の `notes` を画面表示用に絞り込む。既存の 3 列 Navigation と自動保存を維持する。

**Tech Stack:** Swift 6、SwiftUI、SwiftData、Swift Testing、XCTest UI Test。Deployment Target は iPadOS 17。新規外部依存なし。

**Spec:** [Phase 3 要求と Acceptance Criteria](../../requirements/phase-3-app-state-and-search.md)、[ADR-0006](../../adr/0006-phase-3-tags-and-search-state.md)。

## 作業開始条件

- [x] 人間から実装開始の明示的な指示を受ける。計画の作成・承認を開始指示と扱わない。
- [x] `origin/develop` の最新状態を取得し、専用ブランチと Git Worktree を確認する。基点が進んでいれば、作業ブランチを最新の `origin/develop` に合わせる。変更、Build、Test はその Worktree 内だけで行う。
- [x] [AGENTS.md](../../../AGENTS.md)、要求、ADR-0001・0002・0004・0005・0006、[Definition of Done](../../development/definition-of-done.md)を再確認する。

## Task 1: Tag スキーマと旧ストアのデータ保持

**対象:** `ResearchNotebook/Tag.swift`、`ResearchNotebook/Note.swift`、`ResearchNotebook/ResearchNotebookApp.swift`、`ResearchNotebookTests/SwiftDataPersistenceTests.swift`。

- [x] 複数 Note が一つの Tag を参照でき、Note・Project を削除しても Tag は残る振る舞いを Swift Testing に記述し、失敗を確認する。
- [x] `Tag` を独立した `@Model` として追加し、Note との Relationship と全 `ModelContainer` 構成へ登録する。既存の Project・Note フィールドと削除規則を変えない。
- [x] メモリ上とディスク上のコンテナで、タグの再利用、関連の保存・再取得、Note・Project 削除後の Tag 保持を確認する。
- [x] Phase 2 版で Project と Note を保存した旧ストアの**コピー**を新版で開く。Project・Note の件数、ID、タイトル、本文、所属関係の一致を確認する。自動移行の成功を推測で済ませない。
- [x] 自動移行に失敗した場合は元ストアを消去・置換せず、`SchemaMigrationPlan` の候補と影響を整理して作業を止め、人間の判断を受ける。移行方式が決まるまで次の Task に進まない。（自動移行が成功したため停止条件は発生せず）

## Task 2: タグ名と関連付けの規則

**対象:** `ResearchNotebook/Tag.swift`、`ResearchNotebook/Note.swift`、必要なら小さなタグ操作関数、`ResearchNotebookTests/SwiftDataPersistenceTests.swift`。

- [x] 前後の空白除去、空白だけの拒否、大文字・小文字だけが異なる名前での既存 Tag 再利用、同じ Note への二重付与防止をテストする。
- [x] Note への付与・解除を実装する。解除では Tag 自体を削除せず、別 Note の関連を変えない。
- [x] 保存後に別の `ModelContext` から再取得し、複数 Project の Note が同じ Tag を参照できることを確認する。

## Task 3: Note のタグ操作 UI

**対象:** `ResearchNotebook/NoteEditorView.swift`、必要ならタグ選択用の小さな View、`ResearchNotebookUITests/ResearchNotebookUITests.swift`。

- [x] 既存 Tag の選択、新規 Tag の作成、Note からの解除を操作できる UI を追加する。タグ名の変更と全体削除の操作は追加しない。
- [x] 有効な変更を既存の自動保存方針に沿って保存する。保存失敗は画面に示し、成功したように見せない。失敗時に他の Note・Tag を失わないことを確認する。
- [x] UI Test で付与、解除、別 Note での再利用、再起動後の保持、保存失敗時の表示を確認する。VoiceOver にタグ名と選択状態が伝わるラベルを付ける。

## Task 4: Project 内検索と空結果

**対象:** `ResearchNotebook/ContentView.swift`、`ResearchNotebook/NoteListView.swift`、必要なら一覧の絞り込み関数、`ResearchNotebookTests`、`ResearchNotebookUITests/ResearchNotebookUITests.swift`。

- [x] `ContentView` が検索語を `@State` で所有し、選択中 Project の Note 一覧に対してタイトル・本文の検索を適用する。検索対象は Project 内と明示する。
- [x] タイトル一致、本文一致、不一致、空検索語、他 Project の除外を振る舞いのテストで確認する。入力中に結果が更新され、検索語を消すと全件が戻ることを UI Test で確認する。
- [x] Note が 0 件の場合と検索結果が 0 件の場合に別の説明を表示し、両方を UI Test で確認する。
- [x] `searchable` の配置を iPad 全画面と狭いウインドウで確認する。標準の 3 列 Navigation を変更する必要が出た場合は ADR-0004 と照合し、人間の判断を受ける。2026-10-06 に人間が狭いウインドウでも表示されることを直接確認した。

## Task 5: タグフィルタと選択整合

**対象:** `ResearchNotebook/ContentView.swift`、`ResearchNotebook/NoteListView.swift`、`ResearchNotebookTests`、`ResearchNotebookUITests/ResearchNotebookUITests.swift`。

- [x] `ContentView` が選択タグ ID を `@State` で所有し、選択中 Project の一覧に一つのタグ条件を適用する。検索語との併用は AND とする。
- [x] タグ単独、検索語との併用、条件解除、他 Project の除外をテストする。Project 切替後も検索語とタグ条件を保持して新しい Project に適用し、隠れた Note を詳細に残さない。
- [x] 検索・フィルタ変更、Project 切替、Note・Project 削除で表示対象から外れた Note の選択 ID を解除する。データ自体は検索・フィルタで変更しないことをテストする。
- [x] UI Test で、選択 Note が条件から外れた後の詳細の空状態と、条件解除後に Note が再表示されることを確認する。

## Task 6: Phase 3 の総合確認と記録

**対象:** `docs/learning/phase-3.md`、必要な要求・ADR 文書、変更したテスト。

- [ ] `scripts/build.sh` と `scripts/lint.sh` を実行し、新規コンパイラ警告を残さない。
- [ ] 利用可能な iPad Simulator の UDID を指定して `scripts/test.sh` を実行する。Swift Testing と XCTest UI Test の結果を区別して記録する。CI の Build 成功を Simulator テスト成功と扱わない。
- [ ] 可変ウインドウ幅、Dark Mode、Dynamic Type、VoiceOver、キーボードでタグ操作と検索を確認する。確認環境と直接観測できなかった項目を学習ログに記録する。
- [ ] Acceptance Criteria と Definition of Done を照合する。`git diff --check` を実行し、作業ブランチを push して `develop` 向けの日本語タイトル・本文の PR を作成する。

## 停止条件

- 状態管理を `@Observable` 型などへ変更する必要が生じた場合は、実装を止め、具体的な問題、代替案、ADR-0001 の更新要否を人間に提示する。
- 旧ストアのデータ保持を確認できない場合や、承認済み要求・ADR と矛盾する変更が必要な場合は、実装を止めて人間の判断を受ける。
