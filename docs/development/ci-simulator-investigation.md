# CI Simulator 起動と所要時間の検証

確認日: 2026-10-04

## 基準値と失敗の位置

| Run | 結果 | Build | Test | 主な観測 |
|---|---|---:|---:|---|
| [37187392678](https://github.com/Naohiro-Kubota/research-notebook/actions/runs/37187392678) | 成功 | 約19秒 | 約8分25秒 | Test 開始から最初のテストまで約7分22秒。UI Test 自体は約17秒。 |
| [37188593597](https://github.com/Naohiro-Kubota/research-notebook/actions/runs/37188593597) | 失敗 | 約21秒 | 約16分38秒 | `app.launch()` が約165秒後にタイムアウトし、失敗時の Simulator 診断収集が600秒タイムアウト。 |

失敗 run では Swift Testing が成功し、UI Test の `app.launch()` で停止した。成功 run から失敗 run までの変更は文書のみ。Simulator または Xcode UI Test の起動経路が原因候補だが、下位原因は未確定。

## 順次検証する変更

1. 選択した iPad Simulator の状態をログに残し、`xcrun simctl bootstatus "$SIMULATOR_UDID" -b` で起動完了を待ってからテストする。所要時間と成否を確認する。
2. 1 の結果を確認したうえで `-parallel-testing-enabled NO` を単独で追加し、テスト時間と起動失敗の有無を比較する。
3. 失敗時の診断収集を `-collect-test-diagnostics never` で抑制し、失敗時の上限時間を確認する。診断情報を失うため、起動失敗の調査結果を先に記録する。
4. 同じ Pull Request の古い run を `concurrency` で取り消し、連続 push 時の実行時間の浪費を減らす。個々の run の速度には影響しない。

各変更は別コミット・別 CI run で確認し、後続の結果を追記する。

## 第1段階の結果

[run 37190856538](https://github.com/Naohiro-Kubota/research-notebook/actions/runs/37190856538) は Build / Test とも成功し、ジョブ全体は4分34秒だった。選択時の iPad Pro 13-inch (M5)／iPadOS 27.0 は `Shutdown`。`bootstatus -b` は起動完了まで約52秒だった。Test ステップは1分55秒で、UI Test は約9秒で成功した。

ただし、起動完了後に状態を再表示するための `simctl list devices available` が約51秒かかった。この確認コマンドはテストの成否に不要なので除去し、同じ起動待ち条件で再測定する。1回の成功だけで起動失敗の再発防止は判断しない。

[再測定 run 37191182824](https://github.com/Naohiro-Kubota/research-notebook/actions/runs/37191182824) も Build / Test は成功したが、ジョブ全体は8分48秒、起動待ちは1分09秒、Test は6分08秒だった。1回目より大幅に遅く、起動待ちだけで安定した時間短縮が得られたとはいえない。次は既存の共通 `scripts/test.sh` に `-parallel-testing-enabled NO` のみ追加して比較する。

## 第2段階の結果

[run 37191725775](https://github.com/Naohiro-Kubota/research-notebook/actions/runs/37191725775) は Build / Test とも成功し、ジョブ全体は6分35秒、起動待ちは1分18秒、Test は3分59秒だった。直列実行で UI Test 起動失敗は起きなかった。Test は直前の再測定より短いが、起動待ちを導入した最初の run より長い。これらの測定だけでは直列化による速度・安定性の改善を確定できない。

次は失敗時の診断収集を抑制する。成功 run では失敗時の時間短縮を実測できないため、その効果は未検証として記録する。

## 第3段階の結果

`-collect-test-diagnostics never` を追加した [run 37192120950](https://github.com/Naohiro-Kubota/research-notebook/actions/runs/37192120950) は Build / Test とも成功し、ジョブ全体は6分06秒、起動待ちは56秒、Test は4分11秒だった。ローカルでも同じ設定で Build と全テストが成功した。失敗時の診断収集は発生していないため、600秒の診断待ちを短縮できるかは未検証。Xcode が収集する失敗時の詳細診断を失う点は、この設定のトレードオフである。

## 第4段階の確認

Workflow の `concurrency` は Workflow 名と PR の ref をグループキーにして、同じ PR への連続 push で古い実行を取り消す。異なる PR の run は別グループになる。これは個々の run の Test 時間を短縮しない。

確認に使用した一次情報（2026-10-04 確認）:

- [Apple Xcode 10 Release Notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-10-release-notes): 並列テストでは Simulator の複製を使う場合がある。今回の失敗 run で複製が原因だったかは不明。
- [Apple: Organizing tests to improve feedback](https://developer.apple.com/documentation/xcode/organizing-tests-to-improve-feedback): テスト診断収集の設定を確認。今回の適用案は失敗時の診断収集を省くこと。
- [GitHub: Control workflow concurrency](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency): 同じグループの進行中 run を `cancel-in-progress` で取り消せる。今回の適用案は Workflow 名と PR ref の組み合わせ。
- ローカルの `xcrun simctl help bootstatus` と `xcodebuild -help`: `bootstatus -b`、`-parallel-testing-enabled NO`、`-collect-test-diagnostics never` の指定を確認。
