# Phase 3 学習ログ — アプリ状態と検索

確認日: 2026-10-05。Task 1（Tag スキーマと旧ストアのデータ保持）の結果を記録する。Phase 3 全体は未完了。

## Apple 公式資料で確認した事実

| 資料 | 公式資料の事実 | このアプリへの適用 |
|---|---|---|
| [Defining data relationships with enumerations and model classes](https://developer.apple.com/documentation/swiftdata/defining-data-relationships-with-enumerations-and-model-classes) | SwiftData はモデル間の Relationship を管理し、削除規則を指定できる。 | Note と共有 Tag に双方向の Relationship を設けた。 |
| [ModelContainer](https://developer.apple.com/documentation/swiftdata/modelcontainer) | 対応できるスキーマ変更は自動移行し、それを超える変更には `SchemaMigrationPlan` を指定できる。 | Phase 2 ストアのコピーを新スキーマで開き、データ保持を検証した。 |
| [Relationship.DeleteRule.nullify](https://developer.apple.com/documentation/swiftdata/schema/relationship/deleterule-swift.enum/nullify) | 関連モデルを削除したとき、残るモデルから削除済みモデルへの参照を取り除く。 | Tag を残したまま Note を削除する関係に採用した。 |

## Task 1 の実装と実測

- `Tag` を独立した SwiftData `@Model` とし、`Note.tags` と `Tag.notes` を逆関係にした。すべてのアプリ用 `ModelContainer` に Tag を登録した。Project と Note の既存フィールド、および Project から Note への `.cascade` は変更していない。
- iPadOS 17.2 Simulator のメモリ内・ディスク保存先で、一つの Tag を別 Project の Note と共有し、別コンテキストから再取得した。Note 単体削除と本番と同じ条件付き Project 削除で、Note が消え、共有 Tag と未使用 Tag が残ることを確認した。
- `Tag.notes` が必須配列の場合、タグ付き Note を含む Project の条件付き削除が `NSCocoaErrorDomain 134050` で失敗した。`Tag.notes` を optional 配列にすると同じテストが成功した。これは上記 Simulator の実測であり、Apple 公式資料にこの組合せの動作保証があるという意味ではない。候補とログは [旧ストア fixture の記録](../../ResearchNotebookTests/Fixtures/README.md)に残した。
- Phase 2 モデルで作った合成ストアの**コピー**を新版で開き、2 Project、4 Note の件数、ID、タイトル、本文、所属関係が一致し、タグが空であることを確認した。元 fixture のバイト列も変わっていない。任意の実ユーザーストアや別 OS 版の移行成功まで保証する検証ではない。

## Task 1 の Definition of Done

- 承認済み [要求](../requirements/phase-3-app-state-and-search.md)と [ADR-0006](../adr/0006-phase-3-tags-and-search-state.md)のうち、Task 1 が担当する共有 Tag、削除後の保持、旧ストアのデータ保持を満たした。タグ名規則・付与 UI・検索は後続 Task の対象。
- `scripts/build.sh`、`scripts/lint.sh`、`git diff --check` は成功。Swift Testing 12 件と XCTest UI Test 15 件が iPadOS 17.2 Simulator で成功した。新規 Swift コンパイラ警告はない。AppIntents メタデータ抽出省略の既存ツール警告のみ確認した。
- 新規 UI はない。Phase 3 の可変幅、Dark Mode、Dynamic Type、VoiceOver、キーボードの操作確認は、タグ操作と検索 UI が入る後続 Task で行う。Phase 3 全体の Definition of Done は未達。

## Task 2・3: タグ名規則と Note のタグ操作

確認日: 2026-10-06。

### Apple 公式資料で確認した事実

| 資料 | 公式資料の事実 | このアプリへの適用 |
|---|---|---|
| [ModelContext.save()](https://developer.apple.com/documentation/swiftdata/modelcontext/save()) | 未保存の変更を永続ストアに書き込み、失敗をエラーとして伝える。 | タグの付与・解除後に保存を試み、失敗を画面に示す。 |
| [Query](https://developer.apple.com/documentation/swiftdata/query) | 取得した永続モデルを基になるデータと同期する。 | 編集画面の既存 Tag 一覧に `@Query` を使う。 |
| [SwiftUI Accessibility modifiers](https://developer.apple.com/documentation/SwiftUI/View-Accessibility) | `accessibilityLabel(_:)` で要素の内容を伝えられる。 | Tag 名と付与状態を読み上げられるラベルを設定する。 |

前後の空白除去、空白入力の拒否、大文字・小文字が異なる名前の再利用、保存失敗時のロールバックは、このプロジェクトの要求と実装判断である。Apple 公式資料がこれらのアプリ固有規則を指定しているわけではない。

### 実装範囲

- Tag 操作関数で入力を正規化し、同名 Tag を再利用する。同じ Note に二重付与せず、解除しても Tag 自体と他の Note の関連を残す。
- Note 編集画面に既存 Tag の付与・解除と新規 Tag 入力を追加した。既存の保存ボタンなしの方針を維持し、保存失敗時はロールバックしてアラートを表示する。タグ名変更と全体削除は設けていない。
- Swift Testing でメモリ内・ディスク上の別 Context から再取得し、別 Project での共有と保存失敗後の既存データ保持を検証する。XCTest UI Test では新規付与、既存 Tag の再利用、解除、再起動後の状態、読み取り専用ストアでの失敗表示を検証する。

### Task 2・3 の検証

- iPadOS 17.2 の iPad Pro (11-inch) Simulator で `scripts/build.sh` と `scripts/lint.sh` が成功した。Swift Testing 15 ケース、XCTest UI Test 17 件が成功し、失敗は 0 件。新規コンパイラ警告はなく、AppIntents メタデータ抽出省略の既存ツール警告だけを確認した。
- 読み取り専用ストアで Tag 作成と解除の保存失敗を再現し、既存の 2 Note と共有 Tag が残ることを Swift Testing で確認した。UI Test では失敗アラート直後に未保存 Tag が一覧へ現れず、既存 Note 本文が残ることと、再起動後の同じ状態を確認した。
- 標準 Form、TextField、Button を使用し、色に加えてチェックマークとラベルで付与状態を示す。UI Test で Tag 名と付与状態のアクセシビリティラベルを照合した。VoiceOver の実音声操作、可変ウインドウ幅、Dark Mode、Dynamic Type、外部キーボード操作はこの自動テストでは直接観測しておらず、Phase 3 総合確認で扱う。

## Task 4: 選択中 Project の検索

確認日: 2026-10-06。

- [Adding a search interface to your app](https://developer.apple.com/documentation/SwiftUI/Adding-a-search-interface-to-your-app) によると、`searchable` は `NavigationSplitView` の列内 View に付けられ、iPadOS での検索欄の位置は修飾子を付ける場所によって変わる。検索語の保存先はアプリ側が用意する。これに従い、Note 一覧の列に検索欄を置き、`ContentView` の `@State` から Binding を渡した。
- 検索欄の案内文「このProject内のNoteを検索」と、空結果の説明で対象範囲を示す。タイトル・本文の大文字小文字を区別しない部分一致、入力中の更新、空文字への復帰はアプリ固有の実装であり、Apple の資料が検索方式を指定するものではない。
- 選択 Note が検索結果から外れた場合は詳細選択を解除する。これは ADR-0006 の条件と矛盾させないため、Task 5 の一般的な選択整合に先立って検索部分だけを実装した。タグ条件と Project 切替時の条件保持は Task 5 に残す。
- 空 Project と検索結果 0 件には別の説明を表示する。検索は画面上の一覧だけを絞り、保存済み Note を変更しない。

- iPadOS 17.2 の iPad Pro (11-inch) Simulator で `scripts/build.sh`、`scripts/lint.sh`、`git diff --check` が成功した。Swift Testing 16 ケースと XCTest UI Test 19 件は逐次実行で失敗 0 件。最初の並列テスト実行では Swift Testing runner が途中で再起動したため、完了結果に数えず、逐次実行で全件を再検証した。新規 Swift コンパイラ警告はなく、AppIntents メタデータ抽出省略の既存ツール警告のみ確認した。
- iPadOS 27 の iPad Pro 13-inch Simulator で全画面を目視し、検索欄が Note 一覧の列にあり、「このProject内のNoteを検索」が表示されることを確認した。検索欄の Accessibility ラベルは UI Test で照合した。色だけで結果を表さず、空結果にはテキストを表示する。狭いウインドウへの変更は、`ウインドウ表示アプリ` が有効な Simulator で角ドラッグと上端ジェスチャを試したが、画面が消えて実観測できなかった。この時点では Task 4 の狭幅確認と可変幅に関する DoD は未達だった。

2026-10-06、人間が狭いウインドウでも検索欄が表示されることを直接確認した。ウインドウ寸法・機種は報告されていない。これにより Task 4 の狭幅表示の確認項目を完了とする。上記の Simulator での未観測という実測はそのまま残す。

Task 4 完了時点では Task 5・6 が残り、Phase 3 全体の Definition of Done は未達だった。

## Task 5: タグフィルタと選択整合

確認日: 2026-10-06。

- Apple 公式の [Model data](https://developer.apple.com/documentation/swiftui/model-data) は View 固有の一時状態に `@State` を使えると説明する。[HIG: Searching](https://developer.apple.com/design/human-interface-guidelines/searching) は検索とフィルタを組み合わせる場面を扱う。これらはタグ条件の所有方式と表示方法の根拠であり、AND 条件や Project 切替時の保持は本プロジェクトの承認済み要求である。
- `ContentView` が選択タグ ID を一時状態として持つ。選択中 Project の Note にタグ条件と既存のタイトル・本文検索を AND で適用する。タグはメニューで一つ選び、「すべてのタグ」で解除できる。メニューのラベルに選択中のタグ名を含め、色だけに依存しない。
- 条件と Project が変わって表示対象から外れた Note の詳細選択を解除する。Note・Project の削除時は既存の削除コールバックも選択 ID を解除する。絞り込みでは SwiftData のモデルを変更しない。
- 空 Project と条件不一致を区別し、後者の説明を検索・タグの両方に使える文言へ変えた。
- iPadOS 17.2 の iPad Pro (11-inch) Simulator で `scripts/test.sh` を実行した。Swift Testing 17 件と XCTest UI Test 20 件がすべて成功した。新しい UI Test は、タグだけが一致する Note と検索語だけが一致する Note を除外し、Project 切替後も両条件が残ることを確認する。Project 切替とタグ条件変更で隠れた Note の詳細が空になること、条件解除で Note が再表示されることも確認した。
- `scripts/build.sh`、`scripts/lint.sh`、`git diff --check` は成功した。新規コンパイラ警告はなく、AppIntents のメタデータ抽出を省略した既存のツール警告だけを確認した。
- 標準の `Menu` を Note 一覧上部に置いた。選択中のタグ名をテキストとアクセシビリティラベルで示す。検索・タグの条件は SwiftData モデルを変更しない。VoiceOver の実音声操作、狭いウインドウでのタグ Menu、Dark Mode、Dynamic Type、外部キーボード操作は今回直接観測していない。Task 6 の総合確認に残すため、Phase 3 全体の Definition of Done は未達。
