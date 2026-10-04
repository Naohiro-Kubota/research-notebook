# Research Notebook — AI駆動開発スターターキット

iPadOS開発の知識をキャッチアップしながら、Codexを利用したAI駆動開発を実践するためのスターターキットです。

## 目的

- iPadOS / Swift / SwiftUIの開発知識を実際のアプリ開発を通じて習得する。
- Apple公式ドキュメント、Human Interface Guidelines（HIG）、WWDCを一次情報として設計判断を行う。
- 人間とAIの責務を明確に分離したAI駆動開発を検証する。
- 設計判断をADRとして記録し、AIによる暗黙の技術判断を防ぐ。
- ビルド、テスト、Lintなど機械的に検証可能なルールはCIで強制する。

## 題材

「Research Notebook」は、調査資料・Webリソース・PDF・画像・メモをプロジェクト単位で整理するiPadOSアプリです。

最終的には次の要素を段階的に扱います。

- SwiftUI
- Observation
- SwiftData
- URLSession / Swift Concurrency
- NavigationSplitView
- Web API
- Drag & Drop
- Keyboard / Pointer
- Files / PDF / Share
- Apple Pencil / PencilKit
- 複数ウインドウ・マルチタスク
- Accessibility
- Swift Testing / UI Testing

## AI駆動開発の基本分担

### 人間

- 要求の決定
- プロダクト上の優先順位
- 重要な設計・アーキテクチャ判断
- ADRの承認
- セキュリティやプライバシーに関する判断
- 各Phaseの完了承認

### AI（Codex）

- Apple公式一次情報の調査
- 選択肢とトレードオフの提示
- 設計案の作成
- 実装
- テスト作成・実行
- ドキュメント更新
- ADR案の作成
- HIG / Accessibility観点のセルフレビュー

AIは重要な意思決定を黙って確定してはいけません。

## 開始方法

1. `AGENTS.md` を読む。
2. `docs/requirements/product-requirements.md` を読む。
3. `docs/development/development-process.md` に従う。
4. `docs/learning/roadmap.md` のPhase 0から開始する。
5. 技術判断が必要になったら `docs/adr/README.md` の手順でADRを作成する。

## Phase 0 の Build / Test

Xcode 27 と iPad Simulator を用意し、リポジトリのルートで実行します。実測環境は Xcode 27.0 (27A266a)、iPadOS 17.2 の iPad Pro (11-inch) (4th generation) です。

```sh
xcrun simctl list devices available
scripts/build.sh
SIMULATOR_UDID='選択したiPadのUDID' scripts/test.sh
```

両スクリプトは共有 `ResearchNotebook` Scheme と worktree 内の `DerivedData/` を使用します。UDID の選び方と失敗時の動作は [scripts/README.md](scripts/README.md)、CI の実測結果は [Phase 0 要求](docs/requirements/phase-0-development-foundation.md)、学習事項は [Phase 0 学習ログ](docs/learning/phase-0.md)を参照してください。現行 CI は Pull Request で起動します。

## ディレクトリ

```text
.
├── AGENTS.md
├── README.md
├── docs/
│   ├── requirements/
│   ├── architecture/
│   ├── adr/
│   ├── development/
│   └── learning/
├── skills/
│   ├── apple-platform/
│   ├── swiftui/
│   ├── networking/
│   └── testing/
├── scripts/
└── .github/workflows/
```

`skills/` はCodexに与えるプロジェクト固有の知識・チェックリスト置き場です。公式情報のコピーではなく、参照先・確認手順・プロジェクトで採用した知識を管理します。
