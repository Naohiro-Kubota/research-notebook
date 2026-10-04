# 開発スクリプト

リポジトリのルートで実行する。Xcode 27 が必要。Build とローカルの Simulator テストは共有 `ResearchNotebook` Scheme とリポジトリ内の `DerivedData/` を使用し、コード署名を無効にする。

## Lint / Format

Xcode 同梱の `swift format` を使う。`.swift-format` はインデントを 2 スペースに設定し、その他はツールチェーンの既定値を使用する。アプリと Unit / UI Test の Swift ソースが対象で、生成コードは含めない。

```sh
scripts/lint.sh
scripts/format.sh
```

`scripts/lint.sh` はファイルを変更せず、診断があれば失敗する。Pull Request CI でも同じスクリプトを実行する。`scripts/format.sh` は対象ファイルを上書きするため、実行後に差分を確認する。Xcode の版を更新する際は、整形差分と診断を再確認する。

## Build / Test

```sh
scripts/build.sh
```

Swift Testing と XCTest UI Test はローカルの iPad Simulator で実行する。テスト前に利用可能な UDID を調べる。

```sh
xcrun simctl list devices available
SIMULATOR_UDID='選択したiPadのUDID' scripts/test.sh
```

`SIMULATOR_UDID` を省略すると説明を表示して失敗する。存在しない UDID や Simulator サービスの障害による `xcodebuild` の失敗も、そのまま終了コードとして返す。

CI は `scripts/build.sh` の後、Simulator を必要としない `python3 scripts/test-ci.py` で生成アプリの Bundle Identifier、最低 iPadOS バージョン、iPad 専用設定を検査する。CI では Swift Testing と UI Test は実行しない。Workflow は `.github/workflows/build-test.yml`。CI の実行時間と方針変更の経緯は `docs/development/ci-simulator-investigation.md` に記録した。
