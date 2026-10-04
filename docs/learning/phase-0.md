# Phase 0 学習ログ

確認日: 2026-10-04

## 実装したもの

- iPad 専用の最小 SwiftUI アプリ（`ResearchNotebook`、Bundle Identifier `com.tabfav`、iPadOS 17 以降）。
- Swift Testing の Unit Test Target、XCTest の UI Test Target、両方を含む共有 Scheme。
- ローカルと GitHub Actions で共通の `scripts/build.sh` と `scripts/test.sh`。
- Pull Request で Build と Test を実行する GitHub Actions Workflow。Task 4 当時は push と Pull Request の両方で成功したが、その後承認済みの変更により現行設定は Pull Request のみになった。

## 学んだ Swift / iPadOS 概念

- **Project / Target / Scheme:** Xcode Project はアプリとテスト Target をまとめ、共有 Scheme の Test アクションに両テスト Target を登録する。`xcodebuild -list` と `-showBuildSettings` で構成を確認した。
- **Simulator:** `xcrun simctl list devices available` で iPad の UDID を選び、`SIMULATOR_UDID` に指定する。未指定・無効な UDID は成功扱いにしない。
- **Swift Package Manager:** 外部 Package は追加していない。Phase 0 の Build は Package の取得を要しない。
- **Swift Testing / XCTest:** 前者で Bundle Identifier、後者でアプリ起動時の `app-title` 表示を検証する。両テストは iPadOS 17.2 Simulator で各 1 件成功した。
- **SwiftUI:** 最小画面は標準の `Text` だけで構成し、Dynamic Type と Light / Dark Mode に追従する。

## Apple 公式資料

| 資料 | URL | 確認日 | 公式資料から分かったことと本プロジェクトへの適用 |
|---|---|---|---|
| Creating an Xcode project for an app | https://developer.apple.com/documentation/Xcode/creating-an-xcode-project-for-an-app | 2026-10-03 | Project にアプリ Target を設ける。iPad 専用設定と Bundle Identifier は生成物でも検証した。 |
| Customizing the build schemes for a project | https://developer.apple.com/documentation/xcode/customizing-the-build-schemes-for-a-project | 2026-10-03 | Scheme の Test アクションにテストを含める。共有 Scheme をローカルと CI で使用する。 |
| Running your app on simulated or physical devices | https://developer.apple.com/documentation/Xcode/running-your-app-on-simulated-or-physical-devices | 2026-10-03 | Simulator を実行先に使用できる。ローカルでは iPadOS 17.2 の iPad を選んだ。 |
| Adding tests to your Xcode project | https://developer.apple.com/documentation/xcode/adding-tests-to-your-xcode-project | 2026-10-04 | テスト Target を Project に追加できる。Swift Testing と XCTest を役割で分けた。 |
| Testing | https://developer.apple.com/documentation/xcode/testing | 2026-10-04 | Swift Testing と XCTest の役割を確認した。ADR-0002 に従って採用した。 |
| Human Interface Guidelines — Accessibility | https://developer.apple.com/design/human-interface-guidelines/accessibility | 2026-10-04 | 文字サイズと読み上げを確認対象にした。読み上げの実操作は未確認。 |

## 画面・アクセシビリティ確認

- iPad Pro (11-inch) (4th generation) と iPad mini (6th generation)、いずれも iPadOS 17.2 の全画面でタイトルが中央に表示され、見切れないことをスクリーンショットで確認した。同一ウインドウの幅変更は 2026-10-04 に人間が確認した。
- iPad Pro で Dark Mode と `accessibility-extra-extra-extra-large` の文字サイズを設定し、白文字と黒背景、タイトルの拡大と非欠けを画像で確認した。
- `Text("ResearchNotebook")` は色以外の文字そのもので内容を伝える。タップ対象や操作可能な要素はない。Keyboard 操作とエラー UI は Phase 0 の最小静的画面では対象外。
- XCTest UI Test は `app-title` の存在を確認した。VoiceOver の実際の読み上げは 2026-10-04 に人間が確認した。作業 worktree の Xcode Project を開けることも、同日に人間が確認した。

## AI の提案で理解しづらかったこと

- 記録なし。人間側の理解度を AI が推測して記入しない。

## 人間が決めた事項・変更した AI の判断

- アプリ名、Bundle Identifier、iPad 専用、Deployment Target、テスト方式、GitHub Actions は承認済み要求と ADR に従った。
- CI の起動契機は Task 4 完了後に人間の承認を経て Pull Request のみに変更された。Task 4 当時の push run は履歴として残す。
- AI の提案を人間が却下した事例は、この Phase の記録からは確認できない。

## 設計上の気づき

- 静的画面に追加の状態管理層や外部依存は不要だった。
- App Intents メタデータ抽出の警告は既出で、Swift コンパイラ警告とは区別して記録する。
- 全画面の異なる iPad での表示と、可変ウインドウ幅での確認は別の検証である。

## 次 Phase で確認したいこと

- Project / Note の具体的な要求とデータモデルは次 Phase の人間による決定を待つ。
