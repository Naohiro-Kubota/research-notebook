# ADR-0002: Swift Testing と XCTest の役割分担

- Status: Accepted
- Date: 2026-10-03
- Decision Owner: Human

## Context

Phase 0 でテスト基盤を作り、後続 Phase の Unit / Integration / UI Test を継続して実行できるようにする。テスト方式はプロジェクト全体へ影響するため、判断と理由を記録する。

## Apple公式情報・一次情報

| 資料 | URL | 確認日 | 要点 |
|---|---|---|---|
| Adding tests to your Xcode project | https://developer.apple.com/documentation/xcode/adding-tests-to-your-xcode-project | 2026-10-03 | Swift Testing と XCTest のテストを同じテスト Bundle に共存させられる。 |
| Testing | https://developer.apple.com/documentation/xcode/testing | 2026-10-03 | Swift Testing は Swift の Unit Test に利用でき、XCTest は UI Test に引き続き利用される。 |
| Running tests and interpreting results | https://developer.apple.com/documentation/xcode/running-tests-and-interpreting-results | 2026-10-03 | Xcode と `xcodebuild test` からテストを実行できる。 |

## Decision Drivers

- Apple 公式の現在のテスト手段を学習できること。
- ローカルで Unit / UI Test を再現でき、CI で Simulator を使わずに継続検査できること（2026-10-04 の改訂）。
- 後続 Phase で重要な振る舞いを検証し、テスト方式による不要な複雑さを増やさないこと。

## Options

### A. Swift Testing を Unit / Integration Test、XCTest を UI Test に使う

**メリット**

- Swift のコードを Swift Testing で検証し、UI 自動操作を XCTest で行える。
- Apple の現行ドキュメントに沿って両方の仕組みを学べる。

**デメリット**

- 2 種類のテスト記法を扱う必要がある。

### B. Unit / Integration / UI Test に XCTest を使う

**メリット**

- テスト記法を XCTest に統一できる。

**デメリット**

- Swift Testing の学習機会を Phase 0 と後続 Phase から外すことになる。

## Proposed Decision

Option A。Unit / Integration Test は Swift Testing、UI Test は XCTest を使う。Phase 0 では、テスト実行経路を検証できる最小のテストを追加する。テストは実装詳細ではなく振る舞いを検証する。

## Human Decision

2026-10-03、Option A と本 ADR を承認。

2026-10-04、CI の Simulator 実行時間と成否が不安定な実測を受け、人間が実行環境の分担を変更した。Swift Testing / XCTest の採用は維持し、Simulator が必要なテストはローカルで実行する。GitHub Actions は Simulator を起動せず、Build と生成アプリの設定検査を実行する。将来 Simulator を必要としないテストが増えた場合は CI に追加できる。

2026-10-06、人間が今後の作業を含む確認担当を決定した。Simulator の画面・設定・入力を手動操作して確認する項目は人間だけが実施する。自動テストの対象は Swift Testing と XCTest に限り、既存の XCTest UI Test を Simulator で自動実行する方針は維持する。AI は手動 Simulator 操作を代行せず、未確認項目を人間が確認済みと記録しない。

## Consequences

- Xcode Project に必要なテスト Target を設け、Scheme の Test アクションに含める。
- ローカルで `scripts/test.sh` により Swift Testing と XCTest UI Test を実行する。
- GitHub Actions では `scripts/build.sh` と `scripts/test-ci.py` を実行する。CI の成功は Swift Testing / UI Test の成功を意味しない。
- ローカルで Simulator が利用できず、必要なテストを実行できない場合は Phase 0 を完了と報告しない。
