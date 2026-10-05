# Phase 2 学習ログ — SwiftData 永続化

確認日: 2026-10-05。現在は Task 1（永続モデル）までの記録。アプリの画面はまだ Phase 1 のメモリ内モデルを使用しており、Phase 2 の Acceptance Criteria は未達。

## Apple 公式資料で確認した事実

| 資料 | 確認した事実 | このアプリへの適用 |
|---|---|---|
| [Preserving your app’s model data across launches](https://developer.apple.com/documentation/swiftdata/preserving-your-apps-model-data-across-launches) | `@Model`、`ModelContainer`、`ModelContext` でモデルを永続化し、`@Query` で View に取得できる。 | Project と Note を `@Model` とした。View への接続は Task 2。 |
| [Defining data relationships with enumerations and model classes](https://developer.apple.com/documentation/swiftdata/defining-data-relationships-with-enumerations-and-model-classes) | 親の Relationship に `.cascade` を指定すると、親の削除時に関連モデルを削除する。関連グラフの根を `insert` すると子も登録される。 | `Project.notes` に `.cascade` と `Note.project` の inverse を設定した。テストでは親だけを `insert` した。 |
| [ModelContext.autosaveEnabled](https://developer.apple.com/documentation/swiftdata/modelcontext/autosaveenabled) | メインコンテキストは自動保存が有効で、変更後やライフサイクルの変化時に保存する。 | 各文字入力直後のディスク保存は保証されないため、再起動テストを Task 4 で行う。 |
| [ModelContext.save()](https://developer.apple.com/documentation/swiftdata/modelcontext/save())、[ModelContext](https://developer.apple.com/documentation/swiftdata/modelcontext) | `save()` はエラーを投げる。`didSave` は保存成功後の通知であり、失敗通知ではない。 | 保存失敗の検出・表示方法と再現用保存先は Task 0 の残課題。 |
| [ModelConfiguration](https://developer.apple.com/documentation/swiftdata/modelconfiguration) | メモリ内の保存先を指定できる。 | モデルテストは `isStoredInMemoryOnly: true` の独立したコンテナを使用した。 |
| [iOS & iPadOS 17 Release Notes](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-17-release-notes) | SwiftData と `@Query` は iOS・iPadOS 17 で利用できる。 | Deployment Target の iPadOS 17 と整合する。 |
| [Deleting persistent data from your app](https://developer.apple.com/documentation/swiftdata/deleting-persistent-data-from-your-app) | `ModelContext.delete(model:where:)` でモデルを条件付き削除でき、サンプルは `.cascade` による子の削除を説明している。 | Task 3 で Project 単体の条件付き削除を検証する。 |

Xcode 27 SDK の SwiftData インターフェースでも、`@Model`、`@Relationship`、`ModelContainer`、`ModelContext`、`ModelConfiguration` の iOS 17 以降での利用条件を確認した。

## 実装と確認結果

- Project と Note に UUID、必須タイトル用の検証関数、本文、所属 Relationship を定義した。同名でも UUID で区別する。本文は空文字を許す。`Note.project` は SwiftData の双方向 Relationship のため optional とし、作成時の引数では Project を必須にした。
- 別の `ModelContext` から Project と Note の属性・所属を再取得できた。同名 Project・Note の識別と空白タイトル検証を Swift Testing で確認した。
- 連鎖削除を先行調査したところ、iPadOS 17 Simulator のメモリ内コンテナで `ModelContext.delete(project)` の後に所属 Note が残った。一方、同じデータを `delete(model: Project.self, where: ...)` で削除すると Note も消えた。これはこの環境での観測であり、Apple が一般的な動作として保証しているという意味ではない。Task 3 でディスク保存先を含めて再検証し、承認済みの `.cascade` 方針のまま実装する。

## 残課題

- Task 0: 暗黙の自動保存で失敗を検出する方法は公式資料で確認できていない。エラーを検出できる `save()` を利用した保存方法と失敗再現用保存先を検証し、Task 4 の UI へ具体化する。
- Task 2〜5: View の SwiftData 接続、単体削除、自動保存と失敗表示、再起動 UI Test、iPad の操作・Accessibility 確認を行う。

## 今回の Definition of Done 確認

- Task 1 のモデルテスト 3 件は成功。全テストは Swift Testing 13 件と UI Test 9 件が成功した。警告修正後にモデルテスト 3 件を再実行し、成功した。
- `scripts/build.sh`、`scripts/lint.sh`、`git diff --check` は成功。Build で出た App Intents の「依存がないためメタデータ抽出を省略」は既存のツール出力であり、ソースの新規警告は修正した。
- 既存 UI は変更していないため、この作業単位での HIG・Accessibility の操作確認は対象外。Phase 2 全体の DoD は、上記残課題があるため未達。
