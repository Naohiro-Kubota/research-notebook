# Build / Test

リポジトリのルートで実行する。Xcode 27 と iPad Simulator が必要。どちらのスクリプトも共有 `ResearchNotebook` Scheme とリポジトリ内の `DerivedData/` を使用し、コード署名を無効にする。

```sh
scripts/build.sh
```

テスト前に利用可能な iPad Simulator の UDID を調べる。

```sh
xcrun simctl list devices available
SIMULATOR_UDID='選択したiPadのUDID' scripts/test.sh
```

`SIMULATOR_UDID` を省略すると説明を表示して失敗する。存在しない UDID や Simulator サービスの障害による `xcodebuild` の失敗も、そのまま終了コードとして返す。

CI も同じスクリプトを呼び出す。Workflow は `.github/workflows/build-test.yml`、Xcode と Simulator の実測結果および成功した run は `docs/requirements/phase-0-development-foundation.md` の Task 4 に記録した。

テストは `-parallel-testing-enabled NO` で直列実行する。`-collect-test-diagnostics never` により失敗時の Xcode の詳細診断収集を省く。CI は選択した iPad Simulator の起動完了を待ち、同じ PR への連続 push では古い run を取り消す。今回の測定と制約は `docs/development/ci-simulator-investigation.md` に記録した。
