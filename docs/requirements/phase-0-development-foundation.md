# Phase 0: 開発基盤

## 背景

ResearchNotebook の後続 Phase を、小さな変更ごとにビルド・テストできる状態にする。Phase 0 は開発基盤を対象とし、Project や Note の機能は実装しない。

## 承認済みの要求・設定

- アプリ名: `ResearchNotebook`
- Bundle Identifier: `com.tabfav`（指定された文字列をそのまま使用する）
- 対象デバイス: iPad
- Deployment Target: iPadOS 17
- Unit / Integration Test: Swift Testing
- UI Test: XCTest
- CI: GitHub Actions
- Git リポジトリは初期化済みのため、再初期化しない。

## Acceptance Criteria

- [ ] iPadOS 17 以降の iPad を対象とする SwiftUI アプリの Xcode Project を開ける。
- [ ] アプリとテストの Target、およびローカルと CI で共通に使う Scheme がある。
- [ ] リポジトリ内に記載された同じ手順で、ローカルの Build と Test が成功する。
- [ ] iPad Simulator で最小アプリの起動を確認できる。
- [x] GitHub Actions が Build と Simulator 不要の検査を実行し、成功結果を確認できる。Swift Testing / UI Test はローカルで実行する（2026-10-04 に人間が方針変更）。
- [ ] 採用した設定、実行手順、参照した Apple 公式資料、学習内容を文書化する。
- [ ] 新規のコンパイラ警告を残さず、Phase 0 に該当する Definition of Done を確認する。

## 対象外

- Project / Note の作成・編集・削除
- SwiftData による永続化
- Web API、外部ライブラリ、Lint / Format ツールの導入
- 実機配布、App Store 公開、署名を必要とする CI 作業

## 設計上の境界

- 最小アプリは起動とテスト基盤の検証に必要な範囲に留める。
- Lint / Format ツールや外部 Package は Phase 0 で導入しない案とする。導入する場合は別途、人間が判断する。
- `docs/adr/0001-native-swiftui-data-flow.md` の承認済み初期方針に従う。
- テスト戦略は承認済みの `docs/adr/0002-testing-strategy.md` に従う。
- GitHub Actions の Xcode 版とコマンドは、利用可能な環境を確認して実装計画で具体化する。CI では Simulator を起動しない（2026-10-04 の方針変更）。

## 検証観点

- 正常系: アプリのビルド、Simulator での起動、テスト実行、CI 成功。
- 異常系: Scheme や Simulator ランタイムが利用できない場合、原因が分かる失敗として報告されること。
- Accessibility / HIG: 最小画面に適用できる VoiceOver、Dynamic Type、Dark Mode と iPad の表示を確認する。

## Apple 公式資料（2026-10-03 確認）

- [Creating an Xcode project for an app](https://developer.apple.com/documentation/Xcode/creating-an-xcode-project-for-an-app)
- [Customizing the build schemes for a project](https://developer.apple.com/documentation/xcode/customizing-the-build-schemes-for-a-project)
- [Running your app on simulated or physical devices](https://developer.apple.com/documentation/Xcode/running-your-app-on-simulated-or-physical-devices)
- [Adding tests to your Xcode project](https://developer.apple.com/documentation/xcode/adding-tests-to-your-xcode-project)
- [Testing](https://developer.apple.com/documentation/xcode/testing)
- [Xcode command-line tool reference](https://developer.apple.com/documentation/xcode/xcode-command-line-tool-reference)
- [SDK and system requirements](https://developer.apple.com/xcode/system-requirements/)

## 現時点の環境確認

- `xcodebuild -version`: Xcode 27.0 (27A266a)。
- `xcrun simctl list devices available`: CoreSimulatorService に接続できず失敗。Simulator の利用可否は実装前に再確認する。

## Task 1 の実測結果（2026-10-03）

- Xcode 27 に同梱されたアプリ Project の雛形を使い、最小 SwiftUI アプリと共有 Scheme を作成した。Xcode の UI 操作は作業環境で許可されなかったため、`xcodebuild` で Project を検証した。
- `xcodebuild build` は `-derivedDataPath /private/tmp/research-notebook-phase0-derived` を指定して成功した。既定の DerivedData 保存先は作業環境から書き込めない。
- 生成されたアプリの Info.plist で Bundle Identifier `com.tabfav`、MinimumOSVersion `17.0`、UIDeviceFamily `2`（iPad）を確認した。
- `xcodebuild test` は `Scheme ResearchNotebook is not currently configured for the test action` で終了した。テスト Target は計画の Task 2 で追加する。
- CoreSimulatorService に接続できないため、iPad Simulator での起動と画面確認は未実施。Phase 0 の Acceptance Criteria と Definition of Done は未達のままとする。
- 当初、Git の実データが書き込み許可のない別ディレクトリにあり、`git add` は `index.lock: Operation not permitted` で失敗した。その後、Task 1 の成果物は作業ブランチ `codex/phase-0-task-1` のコミット `0e0e613` として記録され、`develop` にコミット `cebe9e6` として反映された。Task 2 以降と Phase 0 の Acceptance Criteria は引き続き未完了。

## Task 2 の実測結果（2026-10-04）

- Apple 公式の [Adding tests to your Xcode project](https://developer.apple.com/documentation/xcode/adding-tests-to-your-xcode-project) と [Testing](https://developer.apple.com/documentation/xcode/testing) を 2026-10-04 に再確認した。**公式資料の事実:** Swift Testing は Unit / Integration Test に利用でき、XCTest は UI Test をサポートする。**プロジェクトへの適用:** 承認済み ADR-0002 に従い両者を別 Target に配置した。**推測・未確認:** Xcode の App Intents メタデータ警告がすべての環境で同じように出るかは未確認。
- 承認済みの ADR-0002 に沿い、Swift Testing 用 Unit Test Target と XCTest 用 UI Test Target を追加し、共有 Scheme の Test アクションに含めた。Unit Test の Host Application は `ResearchNotebook`。
- Xcode 27.0 (27A266a) の `xcodebuild -list` でアプリと 2 つのテスト Target、共有 Scheme を確認した。独立した Debug Build は exit 0。Swift コンパイラ警告は確認されなかった。
- iPad Pro (11-inch) (4th generation)、iPadOS 17.2（UDID `33CA3AC8-9A60-42F4-A25A-14DBF86375DA`）で Swift Testing の Bundle Identifier テストと XCTest の UI 起動テストが各 1 件成功した。生成アプリの Info.plist は `com.tabfav`、MinimumOSVersion `17.0`、UIDeviceFamily `[2]`。
- 初回の詳細ログでは、Xcode の App Intents メタデータ抽出が「AppIntents.framework への依存がないためスキップ」と警告した。新しい DerivedData に対する `xcodebuild -quiet ... test` は exit 0 で診断を出さず、xcresult は 2 件成功・失敗 0 件・runtimeWarnings 0 件だった。Swift コンパイラ警告は確認されなかった。
- 今回確認した UI は起動時に `app-title` の静的 Text が存在すること。可変ウインドウ幅、Dark Mode、Dynamic Type、VoiceOver の目視確認と CI 成功は未実施。これらと共通 Build / Test コマンドは Task 3–5 に残るため、Phase 0 の Acceptance Criteria および Definition of Done は未達。

## Task 3 の実測結果（2026-10-04）

- `scripts/build.sh` と `scripts/test.sh` を追加した。両者は共有 Scheme と Worktree 内の `DerivedData/` を使い、Bundle Identifier を上書きしない。実行方法と iPad Simulator の UDID の調べ方は `scripts/README.md` に記載した。
- Xcode 27.0 (27A266a) で `scripts/build.sh` は exit 0、`BUILD SUCCEEDED`。iPad Pro (11-inch) (4th generation)、iPadOS 17.2（UDID `33CA3AC8-9A60-42F4-A25A-14DBF86375DA`）で `scripts/test.sh` は exit 0、Swift Testing と XCTest UI Test が各 1 件成功した。
- `SIMULATOR_UDID` 未指定は説明付きで exit 2、無効な UDID は `xcodebuild` の失敗を保持して exit 70 となった。
- Build の詳細ログには Task 2 で記録済みの App Intents メタデータ抽出警告が出た。今回の Swift コンパイラ警告は確認されなかった。CI の成功、画面の目視確認、学習ログ、Phase 0 全体の Definition of Done は Task 4–5 に残る。

## Task 4 の実測結果（2026-10-04）

- GitHub 公式の [GitHub-hosted runners reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners) と [actions/checkout](https://github.com/actions/checkout) を 2026-10-04 に確認した。**公式資料の事実:** `xcode-27` はプレビューの macOS arm64 ランナーであり、`actions/checkout@v7` は現在の利用例に掲載されている。**プロジェクトへの適用:** Workflow の実行先を `xcode-27` に固定し、checkout v7 と Task 3 の共通スクリプトを使用する。**推測・未確認:** プレビューランナーの可用性と搭載 Simulator は今後変わり得るため、実行のたびに iPad を検出する。
- ローカルの Xcode 27.0 (27A266a) で `scripts/build.sh` は exit 0、`BUILD SUCCEEDED`。`SIMULATOR_UDID=33CA3AC8-9A60-42F4-A25A-14DBF86375DA scripts/test.sh` は iPad Pro (11-inch) (4th generation)、iPadOS 17.2 で Swift Testing と XCTest UI Test が各 1 件成功した。最初のサンドボックス内 Test は CoreSimulatorService に接続できず exit 70 だったため、Simulator を利用できる実行環境で再実行した。
- GitHub Actions は `xcode-27` 上で Xcode 27.0 (27A266a) と、iPad Pro 13-inch (M5)／iPadOS 27.0（UDID `FC8E648C-B800-4FBC-9401-E362589CA9FF`）を使用した。最終版の [push run](https://github.com/Naohiro-Kubota/research-notebook/actions/runs/37176662702) と [pull request run](https://github.com/Naohiro-Kubota/research-notebook/actions/runs/37176664742) は Build / Test が成功した。最初の実行で checkout v4 の Node.js 20 非推奨警告を確認し、checkout v7 に更新した。最終版のログではその警告はなく、Swift コンパイラの新規警告も確認されなかった。Task 2 から記録済みの App Intents メタデータ抽出警告は引き続き出る。
- Task 4 の Definition of Done は、Build・Test・CI 成功、関連文書更新、対象範囲の警告確認を満たした。画面の目視確認、学習ログ、Phase 0 全体の Definition of Done は Task 5 に残る。
