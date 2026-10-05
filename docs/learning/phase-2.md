# Phase 2 学習ログ — SwiftData 永続化

確認日: 2026-10-05。現在は Task 3（削除）までの記録。Phase 2 全体の Acceptance Criteria は未達。

## Apple 公式資料で確認した事実

| 資料 | 確認した事実 | このアプリへの適用 |
|---|---|---|
| [Preserving your app’s model data across launches](https://developer.apple.com/documentation/swiftdata/preserving-your-apps-model-data-across-launches) | `@Model`、`ModelContainer`、`ModelContext` でモデルを永続化し、`@Query` で View に取得できる。 | Project と Note を `@Model` とし、Task 2 で View を接続した。 |
| [Defining data relationships with enumerations and model classes](https://developer.apple.com/documentation/swiftdata/defining-data-relationships-with-enumerations-and-model-classes) | 親の Relationship に `.cascade` を指定すると、親の削除時に関連モデルを削除する。関連グラフの根を `insert` すると子も登録される。 | `Project.notes` に `.cascade` と `Note.project` の inverse を設定した。テストでは親だけを `insert` した。 |
| [ModelContext.autosaveEnabled](https://developer.apple.com/documentation/swiftdata/modelcontext/autosaveenabled) | メインコンテキストは自動保存が有効で、変更後やライフサイクルの変化時に保存する。 | 各文字入力直後のディスク保存は保証されないため、再起動テストを Task 4 で行う。 |
| [ModelContext.save()](https://developer.apple.com/documentation/swiftdata/modelcontext/save())、[ModelContext](https://developer.apple.com/documentation/swiftdata/modelcontext) | `save()` はエラーを投げる。`didSave` は保存成功後の通知であり、失敗通知ではない。 | 保存失敗の検出・表示方法と再現用保存先は Task 0 の残課題。 |
| [ModelConfiguration](https://developer.apple.com/documentation/swiftdata/modelconfiguration) | メモリ内の保存先を指定できる。 | モデルテストは `isStoredInMemoryOnly: true` の独立したコンテナを使用した。 |
| [iOS & iPadOS 17 Release Notes](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-17-release-notes) | SwiftData と `@Query` は iOS・iPadOS 17 で利用できる。 | Deployment Target の iPadOS 17 と整合する。 |
| [Deleting persistent data from your app](https://developer.apple.com/documentation/swiftdata/deleting-persistent-data-from-your-app)、[ModelContext.delete(_:)](https://developer.apple.com/documentation/swiftdata/modelcontext/delete(_:))、[ModelContext.delete(model:where:includeSubclasses:)](https://developer.apple.com/documentation/swiftdata/modelcontext/delete(model:where:includesubclasses:)) | `delete(_:)` で対象モデルを削除でき、`delete(model:where:)` は条件に一致するモデルを削除する。サンプルは `.cascade` による子の削除を説明している。 | Note は `delete(_:)`、Project は既存の ID 条件付き削除と `.cascade` を使う。Task 3 でディスク保存先の削除結果を検証した。 |

Xcode 27 SDK の SwiftData インターフェースでも、`@Model`、`@Relationship`、`ModelContainer`、`ModelContext`、`ModelConfiguration` の iOS 17 以降での利用条件を確認した。

## 実装と確認結果

- Project と Note に UUID、必須タイトル用の検証関数、本文、所属 Relationship を定義した。同名でも UUID で区別する。本文は空文字を許す。`Note.project` は SwiftData の双方向 Relationship のため optional とし、作成時の引数では Project を必須にした。
- 別の `ModelContext` から Project と Note の属性・所属を再取得できた。同名 Project・Note の識別と空白タイトル検証を Swift Testing で確認した。
- 連鎖削除を先行調査したところ、iPadOS 17 Simulator のメモリ内コンテナで `ModelContext.delete(project)` の後に所属 Note が残った。一方、同じデータを `delete(model: Project.self, where: ...)` で削除すると Note も消えた。これはこの環境での観測であり、Apple が一般的な動作として保証しているという意味ではない。Task 3 では本番と同じディスク保存先で ID 条件付き Project 削除を行い、再起動相当の新しいコンテナから所属 Note の不在と他項目の保持を確認した。

## 残課題

- Task 0 は完了。暗黙の自動保存には公開された失敗通知が確認できなかったため、Task 4 では自動保存を有効に保ち、変更直後の明示的な `save()` でエラーを検出する。詳細は下記。Task 4 の UI とエラー表示は未実装。
- Task 4〜5: 保存失敗表示、追加の再起動 UI Test、iPad の操作・Accessibility 確認を行う。

## 今回の Definition of Done 確認

- Task 1 のモデルテスト 3 件は成功。全テストは Swift Testing 13 件と UI Test 9 件が成功した。警告修正後にモデルテスト 3 件を再実行し、成功した。
- `scripts/build.sh`、`scripts/lint.sh`、`git diff --check` は成功。Build で出た App Intents の「依存がないためメタデータ抽出を省略」は既存のツール出力であり、ソースの新規警告は修正した。
- 既存 UI は変更していないため、この作業単位での HIG・Accessibility の操作確認は対象外。Phase 2 全体の DoD は、上記残課題があるため未達。

## Task 0: 保存失敗経路の調査（2026-10-05）

**Apple 公式資料の事実:** [ModelContext.autosaveEnabled](https://developer.apple.com/documentation/swiftdata/modelcontext/autosaveenabled) は、`mainContext` で有効になり、変更後や画面のライフサイクルに応じて `save()` を呼ぶ。[ModelContext](https://developer.apple.com/documentation/swiftdata/modelcontext) に記載された `didSave` は保存成功後の通知で、失敗通知ではない。[save()](https://developer.apple.com/documentation/swiftdata/modelcontext/save%28%29) はエラーを投げるため、呼び出し元で捕捉できる。`hasChanges` は不要な保存呼び出しの判定に使える。[ModelConfiguration](https://developer.apple.com/documentation/swiftdata/modelconfiguration) の `allowsSave` は保存先の書き込み可否を設定できる。

**実測:** iPadOS 17 Simulator のメモリ内保存先を `allowsSave: false` にすると、保存前に `ModelContainer` の作成が失敗した。書き込み可能なディスク保存先に Project を保存してから同じ保存先を `allowsSave: false` で開き直すと、既存データを取得でき、自動保存有効の `mainContext` で新規 Project の `save()` がエラーを投げた。独立した `ModelContext` から、失敗した変更が保存されていないことも確認した。

**このプロジェクトの方針:** 暗黙の自動保存の失敗を通知で確実に取得する公開 API は確認できなかった。Task 4 では自動保存を維持し、Project / Note の有効な変更直後に `hasChanges` を確認して `save()` を呼び、エラーを画面に表示する。保存ボタンは置かず、失敗した変更を保存済みと表示しない。失敗時の画面状態と、連続入力時の書き込み負荷は Task 4 でテストする。

Task 0 の確認: 読み取り専用ディスク保存先のテストを含む Swift Testing 14 件と既存 UI Test 9 件、Build、Lint、`git diff --check` は成功した。今回の変更はテストと文書のみで、アプリの保存動作と Phase 2 全体の DoD はまだ未完了。

## Task 2: 既存 UI の SwiftData 接続（2026-10-05）

- アプリにローカル `ModelContainer` を設け、Project 一覧を `@Query` から表示する。選択中の Project の `notes` Relationship から Note 一覧を表示し、タイトル・本文は `@Bindable` でモデルへ反映する。選択 ID は View の `@State` に保持する。Phase 1 の `NotebookState` とそのテストは、呼び出しを移行してから削除した。
- UI Test は Debug ビルドの起動引数にテストごとの UUID を渡し、Application Support 内の別々の保存先を使用する。同じテストでの再起動は同じ保存先を使う。通常起動と Release ビルドは既定のローカル保存先を使う。
- `ValidatedTitleField` は共通の `isValidTitle` で空白タイトルをモデルへ渡さない。Phase 1 の `NoteBodyEditor.equatable()` は移植せず、SwiftData へ直接 Binding した本文で連続入力とペーストの既存 UI Test が成功した。
- Project の既存の削除操作は条件付きの `ModelContext.delete(model:where:)` と `.cascade` を使用した。UI 上の削除と選択解除は確認した。所属 Note がディスクからも消えること、他の Project と Note が残ることは Task 3 で検証する。
- iPadOS 17 Simulator で作成・編集・タイトル検証・Project 切替・本文ペースト・再起動後の本文復元の UI Test が成功した。保存失敗の表示は Task 4 の範囲で未実装。Task 2 の新規 UI は標準の SwiftUI フォームと Navigation を維持し、既存の accessibilityIdentifier を引き継いだ。実機の VoiceOver とウインドウ幅の確認は Task 5 に残る。
- 保存先を開けない場合は既存データを消さず、エラー画面を表示する。読み取り専用の存在しないテスト保存先で、起動時クラッシュせずエラー画面になることを UI Test で確認した。通常の保存処理中の失敗表示は Task 4 に残る。
- Task 2 の最終確認: `scripts/build.sh`、Release ビルド、`scripts/lint.sh`、`git diff --check`、Swift Testing 5 件、UI Test 10 件が成功した。Debug 専用の保存先失敗テストも分岐追加後に再実行して成功した。新規の Swift 警告はない。Task 2 の DoD は満たしたが、Note 単体削除、保存失敗表示、Project 削除後のディスク再取得、実操作の確認が残るため Phase 2 全体の DoD は未達。

## Task 3: Note 単体削除と Project の連鎖削除（2026-10-05）

**Apple 公式資料の事実:** [Deleting persistent data from your app](https://developer.apple.com/documentation/swiftdata/deleting-persistent-data-from-your-app) は `ModelContext.delete(_:)` でモデルを削除する例と `.cascade` による関連モデル削除の例を示す。[ModelContext.delete(model:where:includeSubclasses:)](https://developer.apple.com/documentation/swiftdata/modelcontext/delete(model:where:includesubclasses:)) は条件に一致するモデルを削除する。[ModelContext.save()](https://developer.apple.com/documentation/swiftdata/modelcontext/save()) は失敗時にエラーを投げる。

**このプロジェクトの実装:** Note の編集画面に破壊的な削除ボタンと確認画面を設けた。キャンセル時は変更せず、確定時に対象 Note を `delete(_:)` で削除して `save()` する。成功したときだけ選択中の詳細を解除する。保存が失敗した場合はロールバックしてエラーを表示する。Project は Task 2 の ID 条件付き削除と承認済み `.cascade` を継続し、子 Note を手動で削除しない。

**実測:** iPadOS 17.2 Simulator で、Note 削除後に別のコンテキストから対象 Note が消え、同じ Project の他 Note と別 Project が残ることを確認した。Project 削除はディスク保存先を新しいコンテナで開き直し、対象 Project と所属 Note がなく、別 Project と Note が残ることを確認した。UI Test では Note 削除のキャンセル、確定後の詳細解除、アプリ再起動後の状態を確認した。Apple の API 説明と実測を区別し、iPadOS 17 Simulator での挙動を記録している。

**Task 3 の Definition of Done:** `scripts/build.sh`、`scripts/lint.sh`、`git diff --check` は成功。Swift Testing 7 件と UI Test 11 件が成功した。Build に App Intents の依存がないためメタデータ抽出を省略したという既存のツール警告のみがあり、新規の Swift 警告はない。削除操作にはテキスト付きの破壊的ボタンと確認画面を使い、色だけで操作を表していない。SwiftUI 標準の Button と Alert により Accessibility の基本要素を維持した。VoiceOver、最大 Dynamic Type、キーボード操作の実機・手動確認は Task 5 に残る。

**残る確認:** Task 4 で有効な編集値の保存失敗表示と連続入力を扱う。Task 5 で VoiceOver、可変幅、キーボードなどの実操作を確認する。Phase 2 全体の DoD は未達。
