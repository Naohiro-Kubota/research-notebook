# iPadOS学習ロードマップ兼プロダクトバックログ

各Phaseは「機能追加」と「技術学習」をセットにする。

## Phase 0 — 開発基盤

**成果**

- Xcodeプロジェクト作成
- Git初期化
- CodexからBuild/Testを実行可能にする
- CI
- AGENTS.md / ADR運用開始

**学習**

- Xcode Project
- Target / Scheme
- Simulator
- Swift Package Manager
- XCTest / Swift Testingの現状調査

**判断ポイント**

- Deployment Target
- Swift Testing / XCTestの使い分け
- Lint / Format導入要否

## Phase 1 — Notebook基本UI

**成果**

- Project一覧
- Project作成・編集・削除
- Note一覧
- Note作成
- Note編集

Phase 1 の Project / Note はメモリ上で扱う。どちらもタイトルと本文を持ち、タイトルは必須とする。入力は画面上のデータに即時反映する。Project 削除時には所属 Note も削除する。

**学習**

- Swift基礎
- SwiftUI View
- State
- Binding
- Navigation
- NavigationSplitView

## Phase 2 — SwiftData

**成果**

- Project / Note永続化
- Relationship
- 永続化のための保存操作
- Note単体の削除
- Project削除時の所属Note削除を永続化へ反映

**学習**

- @Model
- ModelContainer
- ModelContext
- @Query
- Migrationの考え方

Phase 2 完了後のレビューで許容した課題は[継続課題](../development/phase-2-review-followups.md)に記録する。対応時期は未定。

## Phase 3 — アプリ状態と検索

**成果**

- タグ
- ローカル検索
- フィルタ
- 選択状態

**学習**

- Observation
- @Observable
- 状態所有
- View間データフロー

## Phase 4 — Web API

**成果**

- 外部情報検索
- Loading / Empty / Error表示
- 検索結果からResearch Item保存

**学習**

- URLSession
- HTTP
- Codable
- async/await
- Task / cancellation
- エラー設計
- API DTO
- Network testing

**ADR**

- Web API選定
- Networking境界

## Phase 5 — iPadらしいレイアウト

**成果**

- Sidebar / Content / DetailまたはInspector
- ウインドウ幅への適応

**学習**

- NavigationSplitView
- Inspector
- Size / Layout adaptation
- HIG

## Phase 6 — 複数入力方式

**成果**

- Drag & Drop
- Keyboard Shortcut
- Context Menu
- Pointer利用時の操作性確認

## Phase 7 — Documents

**成果**

- PDF / File取り込み
- Share
- Research Itemへの添付

**学習**

- Files
- PDFKit等の公式Framework調査
- Transferable / ShareLink等の現行API調査

## Phase 8 — Apple Pencil

**成果**

- Research Itemへの手書きメモ

**学習**

- PencilKit
- UIKitとのinteropが必要な場合の考え方

## Phase 9 — Window / Multitasking

**成果**

- 複数ウインドウ
- 状態復元
- 各種ウインドウサイズでの操作

## Phase 10 — 品質強化

**成果**

- Accessibility監査
- UI Test拡充
- Performance確認
- エラーUX改善

**最終レビュー**

「iPhoneアプリを拡大しただけ」になっていないかをHIGと実機操作から確認する。
