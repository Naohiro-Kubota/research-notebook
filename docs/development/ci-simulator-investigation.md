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
