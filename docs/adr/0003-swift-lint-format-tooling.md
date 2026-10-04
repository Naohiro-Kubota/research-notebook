# ADR-0003: Swift の Linter / Formatter を選定する

- Status: Accepted
- Date: 2026-10-04
- Decision Owner: Human

## Context

Phase 0 では Lint / Format ツールの導入を対象外とした。今後の Swift コード増加に備え、ローカルと Pull Request CI で同じ規則を検査し、整形を再現できるようにする。現状の CI は Xcode 27 の `xcode-27` ランナーでビルドと設定テストを実行する。

本 ADR は開発用ツールの判断であり、アプリの実行時依存や UI の変更は提案しない。

## 公式情報・一次情報（2026-10-04 確認）

| 資料 | 確認した事実 | 本プロジェクトへの適用・未確認点 |
|---|---|---|
| [swiftlang/swift-format README](https://github.com/swiftlang/swift-format/blob/main/README.md) | Swift 6 / Xcode 16 以降のツールチェーンに `swift format` が含まれる。`format` と `lint` のサブコマンド、`.swift-format` 設定ファイル、`lint --strict` がある。README は既定スタイルを唯一の Swift 公式スタイルとは位置付けていない。 | Xcode 27 のローカル環境で `xcrun swift format --version` と両サブコマンドのヘルプを確認した。既定の 2 スペース設定では現行 4 ファイルに計 15 件のインデント診断が出た。4 スペース設定では診断 0 件。Xcode 更新時の出力差分は未測定。 |
| [swiftlang/swift-format LICENSE](https://github.com/swiftlang/swift-format/blob/main/LICENSE.txt) | Apache License 2.0 with Runtime Library Exception。 | 同梱ツールをコマンドとして使う場合、追加の Package 依存は不要。 |
| [realm/SwiftLint README](https://github.com/realm/SwiftLint/blob/main/README.md) | Swift のスタイルと規約を検査する。Swift Package plugin、Homebrew などの導入経路があり、設定可能なルールを持つ。README は専用の SwiftLintPlugins リポジトリを plugin 利用時に推奨する。 | 追加導入するならバージョン固定方法、CI との一致、使用ルールの選定が必要。現行ソースへの診断数は未測定。 |
| [realm/SwiftLint LICENSE](https://github.com/realm/SwiftLint/blob/main/LICENSE) | MIT License。 | 外部開発ツールとしてのライセンス確認資料。 |
| [nicklockwood/SwiftFormat README](https://github.com/nicklockwood/SwiftFormat/blob/main/README.md)、[LICENSE](https://github.com/nicklockwood/SwiftFormat/blob/main/LICENSE.md) | 独立した Swift フォーマッタで、CLI と Xcode Extension がある。MIT License。 | 別の整形規則を選ぶ場合の候補。`swift-format` と同時に整形を実行すると規則が競合する可能性がある（設計上の推測）。 |

## Decision Drivers

- ローカルと CI の検査結果が一致し、フォーマットを再現できること。
- 初期導入と Xcode 更新時の保守負担が小さいこと。
- Swift 構文の更新に追随できること。
- 有用な診断を得つつ、重複・不要なルールと既存コードの大量変更を抑えること。
- 外部依存のライセンス、更新、供給元リスクを説明できること。

## Options

| 案 | Linter | Formatter | 利点 | 欠点・リスク |
|---|---|---|---|---|
| A | ツールチェーン同梱の `swift format lint` | 同梱の `swift format format` | 追加インストール不要。単一設定で検査と整形を始められる。Xcode 27 環境で利用可能。 | SwiftLint 固有のルールは使えない。ツールチェーン更新に伴い結果が変わり得る。既定スタイルは本プロジェクトの合意済みスタイルではない。 |
| B | SwiftLint | 同梱の `swift format format` | より多くの規約を個別に検討できる。整形は同梱ツールを利用。 | SwiftLint の追加依存、バージョン固定、二つの設定管理、重複ルールの調整が必要。 |
| C | SwiftLint | nicklockwood/SwiftFormat | 両ツールの設定とルールを細かく選べる。 | 二つの外部ツールの導入・更新・ライセンス管理が必要。Xcode / Swift 更新との互換性確認が増える。 |

## Proposed Decision（AI の提案）

**案 A を最初の採用案として提案する。** 現在の小規模な Swift コードに対しては、同梱の一つのツールで Linter と Formatter の目的を満たせる可能性が高く、外部依存を増やさず試せるためである。これはツールの公式既定スタイルを無条件に採用する提案ではない。

承認後の導入作業では、次を実測・決定する。

1. `xcrun swift format lint --strict` と整形チェックを現行 Swift ファイルに実行し、診断と差分をレビューする。
2. `.swift-format` に最小限の合意済み規則を記録し、対象ファイルと生成ファイルの除外方針を決める。自動整形による既存コード変更は別コミットに分ける。
3. ローカル用スクリプトと Pull Request CI に、ファイルを書き換えない検査を追加する。整形コマンドは開発者が明示的に実行する。
4. Xcode / Swift の更新時にフォーマット差分と lint 結果を再確認する。案 A で必要な診断が不足した場合に、SwiftLint 追加を別途検討する。

案 B / C を選ぶ場合は、具体的に必要なルール、導入経路、バージョン固定、CI インストール時間、重複ルールの扱いを決めてから実装する。外部ライブラリの採用には AGENTS.md に従い人間の承認が必要である。

## Human Decision

2026-10-04、案 A を承認。規模が大きくなり、個別の規約を適用した方がよいと判断した時点で案 B を再検討する。

導入時の設定は、既存コードと一致する 4 スペースのインデントのみを既定値から変更する。対象はアプリと Unit / UI Test の Swift ソースで、生成コードは対象に含めない。CI は `lint --strict` により診断があれば失敗させ、整形は開発者が明示的に実行する。

## Consequences

- 案 A でもフォーマット規則への合意と既存コードの差分確認が必要になる。
- CI が検査を強制すると、Xcode 版を変更した際に規則差分で Pull Request が失敗する可能性がある。
- Linter / Formatter はコンパイラ、テスト、コードレビューの代替にはならない。
- ツール導入後、開発手順と Definition of Done にローカル・CI の実行方法を反映する。
