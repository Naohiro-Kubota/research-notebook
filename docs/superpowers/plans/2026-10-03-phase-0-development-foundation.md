# Phase 0 Development Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** iPad 用 ResearchNotebook の Xcode Project、再現可能な Build / Test、GitHub Actions CI を整える。

**Architecture:** 単一の SwiftUI アプリ Target と Swift Testing / XCTest のテスト Target を使う。ローカルと CI は同じ `scripts/build.sh` と `scripts/test.sh` を呼び出す。Phase 0 では永続化、Web API、外部ライブラリ、追加の状態管理層を設けない。

**Tech Stack:** Xcode 27、SwiftUI、Swift Testing、XCTest、`xcodebuild`、iPad Simulator、GitHub Actions。

**Spec:** `docs/requirements/phase-0-development-foundation.md`。関連判断は `docs/adr/0001-native-swiftui-data-flow.md` と `docs/adr/0002-testing-strategy.md`。

## Global Constraints

- アプリ名は `ResearchNotebook`、Bundle Identifier は正確に `com.tabfav`。
- 対象デバイスは iPad、Deployment Target は iPadOS 17。
- Unit / Integration Test は Swift Testing、UI Test は XCTest。
- CI は GitHub Actions。Git リポジトリを再初期化しない。
- Project / Note、SwiftData、Web API、外部ライブラリ、Lint / Format ツールは Phase 0 で実装しない。
- Apple 固有事項は公式資料を優先し、採用した設定と実測結果を文書に記録する。

## Review Focus

1. Xcode が Bundle Identifier にアプリ名を付加して `com.tabfav.ResearchNotebook` にしていないか。Task 2 の Swift Testing と Task 1 の設定確認で検証する。
2. アプリ Target が iPhone をサポートしていないか。Task 1 の Target 設定確認で検証する。
3. Scheme にテスト Target が入っていないか。Task 2 の `xcodebuild test` と Task 3 の CI で検証する。
4. 利用可能な iPad Simulator がないとき、`test.sh` が成功扱いにならないか。Task 3 の異常系確認で検証する。
5. CI がローカルと異なる Xcode やコマンドを暗黙に使っていないか。Task 4 のログと Workflow 設定の確認で検証する。

---

### Task 1: 最小 SwiftUI アプリの Project

**Files:**
- Create: `ResearchNotebook.xcodeproj/project.pbxproj`
- Create: `ResearchNotebook/ResearchNotebookApp.swift`
- Create: `ResearchNotebook/ContentView.swift`
- Create: `ResearchNotebook/Assets.xcassets/`（Xcode が必要とする最小アセット）
- Modify: `.gitignore`（Xcode のユーザー固有・生成物のみ除外）

**Interfaces:**
- Produces: `ResearchNotebook` アプリ Target と同名の共有 Scheme、画面上で識別できる静的な `ResearchNotebook` 表示。

- [x] **Step 1: Xcode の iOS App テンプレートから Project を作成する。** Interface は SwiftUI、言語は Swift。アプリ Target の Supported Destinations を iPad のみにし、Deployment Target を iPadOS 17、`PRODUCT_BUNDLE_IDENTIFIER` を文字列 `com.tabfav` に設定する。SwiftData テンプレートを選ばない。
- [x] **Step 2: 最小画面を作る。** `ContentView` は `Text("ResearchNotebook")` を表示し、その Text に `accessibilityIdentifier("app-title")` を与える。ナビゲーションや状態管理は加えない。
- [x] **Step 3: Project 設定を検証する。** `xcodebuild -list -project ResearchNotebook.xcodeproj` で Target / Scheme を確認し、`xcodebuild -showBuildSettings -project ResearchNotebook.xcodeproj -scheme ResearchNotebook` で `PRODUCT_BUNDLE_IDENTIFIER = com.tabfav`、`IPHONEOS_DEPLOYMENT_TARGET = 17.0`、iPad のみのデバイス指定を確認する。
- [x] **Step 4: Build する。** `xcodebuild -project ResearchNotebook.xcodeproj -scheme ResearchNotebook -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`。期待結果は exit 0、`BUILD SUCCEEDED`、新規コンパイラ警告なし。
- [x] **Step 5: この作業単位をコミットする。** メッセージ例: `feat: create iPad app foundation`。

Task 1 は 2026-10-03 にコミット `0e0e613` として記録され、`develop` にコミット `cebe9e6` として反映された。Xcode UI を操作できなかったため、Step 1 では Xcode 27 同梱の雛形を利用した。Step 4 の Build には書き込み可能な `-derivedDataPath /private/tmp/research-notebook-phase0-derived` を追加した。Simulator での起動確認とテスト Target の追加は Task 2 以降に残る。

### Task 2: Swift Testing と XCTest のテスト基盤

**Files:**
- Modify: `ResearchNotebook.xcodeproj/project.pbxproj`
- Create: `ResearchNotebookTests/ResearchNotebookTests.swift`
- Create: `ResearchNotebookUITests/ResearchNotebookUITests.swift`
- Create: `ResearchNotebook.xcodeproj/xcshareddata/xcschemes/ResearchNotebook.xcscheme`（Xcode が共有 Scheme を別ファイルに保存する場合）

**Interfaces:**
- Consumes: Task 1 の `ResearchNotebook` アプリ Target、`app-title` 識別子。
- Produces: Swift Testing 用 `ResearchNotebookTests` と XCTest UI 用 `ResearchNotebookUITests`、両方を実行する Scheme。

- [x] **Step 1: テスト Target を作成する。** Xcode の Unit Testing Bundle と UI Testing Bundle を追加する。Unit Test の Host Application は `ResearchNotebook` に設定する。Unit Test は `import Testing`、UI Test は `import XCTest` を使用し、両 Target を `ResearchNotebook` Scheme の Test アクションに含める。
- [x] **Step 2: Swift Testing の設定テストを書く。** `@Test func appUsesApprovedBundleIdentifier()` で、ホストアプリの `Bundle.main.bundleIdentifier` が `com.tabfav` に等しいことを `#expect` で検証する。
- [x] **Step 3: XCTest UI の起動テストを書く。** `func testLaunchShowsAppTitle()` でアプリを起動し、`app.staticTexts["app-title"].exists` を検証する。
- [x] **Step 4: iPad Simulator で両テストを実行する。** `xcrun simctl list devices available` で実行先を確認し、選んだ iPad の UDID を `SIMULATOR_UDID` に設定して `xcodebuild -project ResearchNotebook.xcodeproj -scheme ResearchNotebook -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" CODE_SIGNING_ALLOWED=NO test` を実行する。期待結果は両テスト成功、新規警告なし。
- [x] **Step 5: この作業単位をコミットする。** メッセージ例: `test: establish Swift and UI test targets`。

Task 2 は 2026-10-04 に iPad Pro (11-inch) (4th generation)、iPadOS 17.2（UDID `33CA3AC8-9A60-42F4-A25A-14DBF86375DA`）で検証した。`xcodebuild test` で Swift Testing と XCTest UI Test が各 1 件成功した。Build と Test の生成物は Worktree 内の `DerivedData/` に保存した。Xcode UI を介さず Project 設定へ 2 つのテスト Target を追加した。生成物の Info.plist でアプリの Bundle Identifier `com.tabfav`、MinimumOSVersion `17.0`、UIDeviceFamily `[2]` を確認した。初回の詳細ログで Xcode の App Intents メタデータ抽出が「依存なしのためスキップ」と警告した。新しい DerivedData に対する `xcodebuild -quiet ... test` は exit 0、xcresult は 2 件成功・失敗 0 件・runtimeWarnings 0 件で、Swift コンパイラ警告は確認されなかった。Phase 0 全体の Definition of Done は Task 3–5 が残るため未達。

### Task 3: Codex と CI に共通の Build / Test コマンド

**Files:**
- Create: `scripts/build.sh`
- Create: `scripts/test.sh`
- Modify: `scripts/README.md`

**Interfaces:**
- Consumes: `ResearchNotebook.xcodeproj`、共有 `ResearchNotebook` Scheme、利用可能な iPad Simulator の UDID。
- Produces: リポジトリのルートから実行できる `scripts/build.sh` と `SIMULATOR_UDID=<UDID> scripts/test.sh`。

- [ ] **Step 1: `build.sh` を作る。** Project、Scheme、Debug、generic iOS Simulator、`CODE_SIGNING_ALLOWED=NO` を固定し、書き込み可能なリポジトリ内の `DerivedData/` を `-derivedDataPath` に指定して `xcodebuild ... build` の終了コードをそのまま返す。引数や環境値で Bundle Identifier を上書きしない。
- [ ] **Step 2: `test.sh` を作る。** `SIMULATOR_UDID` が空なら説明を表示して非ゼロ終了し、値がある場合は同じ `DerivedData/` とその iPad Simulator に対して `xcodebuild ... test` を実行する。存在しない UDID やサービス停止時も `xcodebuild` の失敗を隠さない。
- [ ] **Step 3: 正常系を検証する。** `scripts/build.sh` と `SIMULATOR_UDID=<実在するiPadのUDID> scripts/test.sh` を実行し、Build と両テストの成功を確認する。
- [ ] **Step 4: 異常系を検証する。** `env -u SIMULATOR_UDID scripts/test.sh` が説明付きで非ゼロ終了すること、無効な UDID でも成功扱いにならないことを確認する。
- [ ] **Step 5: `scripts/README.md` に実行方法と Simulator の UDID の調べ方を記載し、コミットする。** メッセージ例: `build: add shared build and test commands`。

### Task 4: GitHub Actions CI

**Files:**
- Create: `.github/workflows/build-test.yml`
- Modify: `docs/requirements/phase-0-development-foundation.md`（採用した Xcode / 実行先と検証結果）

**Interfaces:**
- Consumes: Task 3 の `scripts/build.sh` と `scripts/test.sh`。
- Produces: push と pull request で Build / Test を実行する GitHub Actions Workflow。

- [ ] **Step 1: Workflow を作る。** `runs-on: xcode-27`、`actions/checkout`、`xcodebuild -version`、`scripts/build.sh`、iPad Simulator の検出と `scripts/test.sh` の実行を含める。`xcrun simctl list devices available -j` の結果から利用可能な iPad を 1 台選び、その UDID を明示的に `SIMULATOR_UDID` に渡す。実行先がなければ失敗させる。外部 Package の取得や署名・配布手順は加えない。
- [ ] **Step 2: Workflow をレビューする。** アプリ Project と共有 Scheme、2 つのテスト Target、ローカルと同じスクリプト、Xcode 27 の実行ログが確認できることを静的に確認する。
- [ ] **Step 3: 変更をコミットし、GitHub 上で push または pull request の Workflow を実行する。** Build / Test が成功した実際の run URL を記録する。プレビュー扱いの `xcode-27` ランナーで環境起因の失敗が出た場合は、ログと代替案を提示し、成功前に Phase 0 を完了としない。
- [ ] **Step 4: 実測した Xcode 版、Simulator、成功した Workflow run を要求文書へ記録する。** メッセージ例: `ci: verify iPad app build and tests`。

### Task 5: 学習ログと Definition of Done

**Files:**
- Create: `docs/learning/phase-0.md`
- Modify: `README.md`（Xcode と Build / Test の入口）
- Modify: `docs/requirements/phase-0-development-foundation.md`（Acceptance Criteria の実測確認）

**Interfaces:**
- Consumes: Task 1–4 の設定・コマンド・検証結果。
- Produces: 第三者が再現できる手順と Phase 0 の学習記録。

- [ ] **Step 1: 学習ログを記入する。** `docs/learning/phase-log-template.md` の項目に沿い、Project / Target / Scheme / Simulator / Swift Package Manager / Swift Testing / XCTest の学習事項、参照 URL と確認日、人間が決めた事項、次 Phase の課題を書く。
- [ ] **Step 2: README と要求文書を更新する。** Xcode 版、Simulator の選び方、Build / Test コマンド、CI run の URL、Acceptance Criteria の確認結果を記載する。結果のない項目にチェックを付けない。
- [ ] **Step 3: 最小画面を目視確認する。** iPad Simulator で可変ウインドウ幅、Dark Mode、Dynamic Type、VoiceOver の読み上げ、色だけに依存しない表示を確認し、結果を学習ログに記す。UI が単一の静的 Text であるため、対象外の Keyboard 操作とエラー UI は理由を記す。
- [ ] **Step 4: 最終検証する。** `scripts/build.sh`、`SIMULATOR_UDID=<実在するiPadのUDID> scripts/test.sh`、CI の成功ログ、`git diff --check`、新規警告の有無を確認する。Definition of Done に未達項目があれば完了と報告せず、理由と残課題を記録する。
- [ ] **Step 5: 文書をコミットする。** メッセージ例: `docs: record Phase 0 validation and learning`。

## 計画時点の環境リスク

- 2026-10-03 のローカル Xcode は 27.0。`simctl list devices available` は CoreSimulatorService に接続できず失敗した。Task 2 に入る前に Simulator サービスとランタイムを確認する。
- GitHub 公式の [hosted runners reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners) と [runner image](https://github.com/actions/runner-images/blob/main/images/macos/xcode-27-arm64-Readme.md)（2026-10-03 確認）には `xcode-27` があるが、プレビュー扱いである。CI の実行結果で利用可否を判断する。
