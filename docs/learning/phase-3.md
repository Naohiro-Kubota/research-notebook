# Phase 3 学習ログ — アプリ状態と検索

最終確認日: 2026-10-06。Task 1〜6 の結果を記録する。Phase 3 全体の Definition of Done は、Task 6 に残る実操作確認が済むまで未達。

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

## Task 6: Phase 3 の総合確認

確認日: 2026-10-06。

### Apple 公式資料と適用

| 資料 | 公式資料で確認した事実 | このアプリでの判断・実測 |
|---|---|---|
| [HIG: Layout](https://developer.apple.com/design/human-interface-guidelines/layout) | 異なるウインドウサイズと文字サイズでレイアウトを確認するよう勧める。 | 狭いウインドウと大きい文字でタグ入力欄が詰まる実画面を見つけ、配置を修正した。 |
| [DynamicTypeSize.isAccessibilitySize](https://developer.apple.com/documentation/swiftui/dynamictypesize/isaccessibilitysize) | 現在の文字サイズがアクセシビリティ用のサイズか判定できる。 | その場合だけ、タグ入力欄と追加ボタンを縦に並べる。 |
| [SwiftUI Accessibility modifiers](https://developer.apple.com/documentation/SwiftUI/View-Accessibility) | 標準コントロールには基本的なアクセシビリティ情報があり、`accessibilityLabel(_:)` で補足できる。 | タグの名前・付与状態と、選択中のフィルタ名をアクセシビリティツリーで確認した。 |
| [HIG: VoiceOver](https://developer.apple.com/design/human-interface-guidelines/voiceover) | 主要要素を説明する代替ラベルを VoiceOver が読み上げに使う。 | ラベルの内容は確認した。音声そのものは記録できていない。 |

### 実画面と操作

以下の Task 6 の画面・操作記録は方針変更前に AI が観測した履歴であり、人間の確認結果ではない。2026-10-06 に人間が、今後の Simulator 手動操作による確認は人間のみが行い、自動テストは Swift Testing と XCTest に限ると決定した。既存の XCTest UI Test の自動実行は継続する。Task 6 の可変幅・Dark Mode・Dynamic Type・VoiceOver・キーボードの人間による確認は、Task 4 の狭幅検索欄を除き未報告である。

- iPadOS 27.0 の iPad Pro 13-inch (M5) Simulator、Device Hub の小さいアプリウインドウ（画面キャプチャ上で約 690 px 幅）を使用した。人間は Task 4 で狭いウインドウの検索欄を別途直接確認している。
- Dark Mode と Light Mode の両方で、Project 内検索欄、タグ Menu、Note 一覧、編集欄と空結果の説明を視認した。色のほかにタグ名、チェックマーク、付与状態のラベルで状態を示す。
- 隔離した UI 検証ストアで Project と Note を作り、タグを新規付与してフィルタを選択した。検索語を不一致にすると一覧が空になり、詳細選択も解除された。タグ解除後に、アクセシビリティラベルが「付与済み」から「未付与」に変わった。
- Dynamic Type を `accessibility-extra-large` にすると、当初は Note 編集画面のタグ入力欄と追加ボタンが接していた。`NoteEditorView` でアクセシビリティ文字サイズ時に縦配置へ切り替え、同じ狭幅・文字サイズで両方が別行に表示されることを再確認した。検索欄の案内文は狭幅では画面上で一部省略されるが、Project 内という範囲は表示され、アクセシビリティラベルには全体がある。
- Device Hub で VoiceOver を有効化し、フォーカス枠が表示されることを確認した。アクセシビリティツリー上のタグボタンは「タグ Shared、付与済み／未付与」、フィルタは「タグで絞り込む、すべてのタグ／Shared」だった。音声の聞き取りはこの環境から直接確認できていない。
- `Tab` で検索欄とタグ入力欄にフォーカス枠が移ることは観測した。外部キーボードだけで検索語入力、タグ Menu 選択、タグ追加・解除まで完走する操作は確認できていない。

### 自動検証と Definition of Done

- iPadOS 17.2 の iPad Pro (11-inch) Simulator（UDID `33CA3AC8-9A60-42F4-A25A-14DBF86375DA`）で `scripts/build.sh`、`scripts/lint.sh`、`scripts/test.sh`、`git diff --check` が成功した。Swift Testing 17 件と XCTest UI Test 20 件は失敗 0 件。Swift コンパイラ警告は 0 件で、AppIntents メタデータ抽出省略のツール警告だけを確認した。既存テストの `#expect` マクロが出していた 2 件の Swift 警告は、同じ「空」の振る舞いを確認する式に直して解消した。
- 自動テストは共有 Tag、旧ストアのコピーからのデータ保持、タグ名規則と保存失敗、検索・フィルタ、選択解除を対象にする。Apple 公式資料の事実とアプリ固有の AND 条件・選択解除は上記と ADR-0006 で区別している。
- VoiceOver 音声と外部キーボードの主要フローが未観測のため、Phase 3 全体の Definition of Done は現時点で未達。これらの確認が済むまで、Acceptance Criteria の最後の DoD 項目は完了としない。

## Observation UI 状態 Task 1: 一時状態と選択遷移

確認日: 2026-10-06。承認済み [ADR-0007](../adr/0007-observation-ui-state.md) に基づく。

### Apple 公式資料で確認した事実と適用

- [Managing model data in your app](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app) は、`@Observable` マクロが変更追跡を追加し、SwiftUI が View 内で読んだプロパティへの依存を追跡すると説明する。`NotebookUIState` を `@MainActor @Observable` にし、四つの一時状態を保持する。
- 同資料は、Observable インスタンスを View の `@State` に置くと SwiftUI がその保存領域を管理すると説明する。ウインドウのルート View が各インスタンスを所有する方針は本プロジェクトの判断であり、View への接続は Task 2 で行う。
- [Preserving your app’s model data across launches](https://developer.apple.com/documentation/swiftdata/preserving-your-apps-model-data-across-launches) は、`@Model` が永続化用のスキーマと `PersistentModel` 準拠に加え、`Observable` 準拠による変更追跡を追加すると説明する。Project・Note・Tag は永続モデルのままにし、一時状態へ複製しない。

`reconcileSelection(visibleNoteIDs:)` は View が導出する ID 集合だけを受け取り、表示対象から外れた Note 選択のみ解除する。Project 選択、検索語、タグ条件は維持する。SwiftData 型や Context は保持しない。選択解除と状態の分離は承認済みのアプリ固有の要求である。Task 1 の範囲で公式資料と実装の不明点はない。新規 UI はなく、HIG・Accessibility の画面操作による確認は実施していない。

### Task 1 の自動検証と残課題

- iPadOS 17.2 の iPad Pro (11-inch) (4th generation)、UDID `33CA3AC8-9A60-42F4-A25A-14DBF86375DA` を使用。実装前に `scripts/test.sh` が `NotebookUIState` 未定義で失敗することを確認した（終了コード 65）。実装後の同スクリプトは終了コード 0、Swift Testing 24 件（新規 7 件）、XCTest UI Test 20 件、失敗 0 件。
- 初期値、表示中・非表示・空集合での選択整合、未選択、Project 切替を模した集合変更、条件保持、二つのインスタンスの独立性を検証した。
- `scripts/build.sh`、`scripts/lint.sh`、`git diff --check` は成功。新規 Swift コンパイラ警告はなく、既存の AppIntents メタデータ抽出省略のツール警告と、テスト起動時の Xcode debugger version lookup 診断を確認した。
- Task 1 の状態型・自動検証・資料記録は満たした。Task 2 の View への接続、後続の総合確認、Phase 3 の人間による未報告の画面操作確認が残るため、Observation 対応全体と Phase 3 全体の Definition of Done は未達。Simulator の手動操作は実施していない。
