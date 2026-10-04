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
