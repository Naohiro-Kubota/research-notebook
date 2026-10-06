# ADR-0006: Phase 3 のタグと検索状態

- Status: Accepted
- Date: 2026-10-05
- Decision Owner: Human

## Context

[Phase 3 要求案](../requirements/phase-3-app-state-and-search.md)は、Note のタグ、選択中の Project 内のローカル検索とフィルタを追加する。現在の `Project` と `Note` は SwiftData の永続モデルで、選択 ID は `ContentView` の `@State` が所有する。既存の保存データを失わず、承認済みの [ADR-0001](0001-native-swiftui-data-flow.md)、[ADR-0004](0004-three-column-notebook-navigation.md)、[ADR-0005](0005-swiftdata-persistence.md)と整合させる必要がある。

人間は 2026-10-05 に、タグを Phase 3 では Note に付けること、検索を選択中の Project 内に限定すること、条件から外れた Note の詳細選択を解除すること、既存の状態管理方式を変える必要があれば作業を止めて判断を求めることを決定した。同日、Option A と本 ADR を最終承認した。

## Apple 公式情報・一次情報

確認日: 2026-10-05。以下は公式資料に記載された事実であり、後述の採用案とは区別する。

| 資料 | 確認した事実 |
|---|---|
| [Managing model data in your app](https://developer.apple.com/documentation/SwiftUI/Managing-model-data-in-your-app) | Observation の SwiftUI サポートは iPadOS 17 以降。View が読んだ Observable プロパティを追跡し、Binding が必要なら `@Bindable` を使える。 |
| [Model data](https://developer.apple.com/documentation/swiftui/model-data) | View 固有の一時状態には `@State`、所有者から共有する値には Binding を使用できる。Observable 型は `@State` で所有し、Environment で共有する方法もある。 |
| [Adding a search interface to your app](https://developer.apple.com/documentation/SwiftUI/Adding-a-search-interface-to-your-app) | `searchable` は `NavigationSplitView` やその列内の View に付けられる。iPadOS での検索欄の位置は修飾子を付ける場所で変わる。 |
| [Filtering and sorting persistent data](https://developer.apple.com/documentation/SwiftData/Filtering-and-sorting-persistent-data) | Predicate と動的な `Query` で表示する永続モデルを絞り込める。 |
| [ModelContainer](https://developer.apple.com/documentation/swiftdata/modelcontainer) | 対応できるスキーマ変更は自動移行する。自動移行の範囲を超える変更には `SchemaMigrationPlan` を指定できる。 |
| [Preserving your app’s model data across launches](https://developer.apple.com/documentation/swiftdata/preserving-your-apps-model-data-across-launches) | モデル型の属性が別のモデル型またはその配列なら、SwiftData が Relationship を管理する。 |
| [HIG: Searching](https://developer.apple.com/design/human-interface-guidelines/searching)、[HIG: Search fields](https://developer.apple.com/design/human-interface-guidelines/search-fields) | 検索範囲を明確に示し、検索欄の説明文で対象を伝えることを勧める。フィルタによる絞り込みも想定している。 |

Apple の資料だけでは、このアプリの既存ストアを新しいタグスキーマで開けること、Relationship を含む検索 Predicate が iPadOS 17 の実行環境で期待どおり動くことは確認できない。

## Decision Drivers

- タグを複数 Note で再利用でき、既存の Project と Note を保持する。
- Project 内検索という範囲と、選択中の Note の表示を一致させる。
- SwiftUI と SwiftData の標準機能を使い、必要性のない状態管理層や外部依存を増やさない。
- iPadOS 17 と既存の 3 列 Navigation を維持する。

## Options

### A. 共有 Tag モデルと既存の View 所有状態を使う

`Tag` を独立した SwiftData モデルとし、Note と Tag を関連付ける。タグは Project をまたいで Note 間で共有し、Note や Project の削除ではタグ自体を削除しない。検索語、選択タグ、Project・Note の選択 ID は `ContentView` が一時状態として所有し、必要な子 View へ値または Binding を渡す。検索・フィルタは選択中の Project の Note 一覧に適用する。

**利点**

- 一つの Tag を複数 Note に割り当てられる。将来の別種の Research Item への適用を妨げない。
- 現行のデータフローと 3 列 Navigation を維持できる。

**欠点・リスク**

- Tag と Note の Relationship を追加するため、既存ストアからの移行を実データで検証する必要がある。
- 使われなくなった Tag は残る。タグの改名・削除を設ける場合は別途振る舞いを決める必要がある。

### B. Note ごとにタグ名の配列を保存する

各 Note に文字列の配列を保存し、同じ名前を持つタグを画面上でまとめて扱う。

**利点**

- 新しいモデル間 Relationship は要らない。

**欠点・リスク**

- 同名タグの判定や名前変更を、Note を横断する文字列操作で管理する必要がある。
- 複数 Note で共有する一つの Tag という製品概念を表しにくい。

### C. 検索・選択専用の Observable 型を新設する

Option A の一時状態を新しい `@Observable` 型へ移し、View 間で共有する。

**利点**

- 共有する状態と操作が増えた場合、所有者を一つの型として示せる。

**欠点・リスク**

- 現段階では `ContentView` の `@State` と Binding で同じデータフローを表せる。型と受け渡し方式の追加が解決する具体的な問題を確認できていない。
- 状態管理方式の変更として ADR-0001 の再判断が必要になる。

## Proposed Decision

Option A を提案する。Note にだけタグを付け、検索は選択中の Project 内の Note のタイトルと本文を対象にする。一つのタグで絞り込み、検索語と併用した場合は両条件を満たす Note を表示する。条件から外れた Note の詳細選択は解除する。検索欄に Project 内検索であることを示し、空の Project と検索結果なしを区別する。タグ名は前後の空白を除き、空白だけの名前を拒否する。大文字・小文字だけが異なる入力には既存タグを再利用する。Phase 3 ではタグ名の変更と全体からの削除を設けず、未使用のタグを再利用可能な状態で残す。

一時状態は現在の View 所有方式を維持する。`@Observable` の学習では、現行の `@State`、Binding、SwiftData モデルの観測がそれぞれ何を所有するかを資料と実装結果で比較する。実装調査で Observable 型への移行が必要になった場合は、作業を止め、人間に状態管理案と ADR-0001 の更新要否を提示する。

移行方式はまだ決定しない。まず Phase 2 版で Project と Note を保存したストアのコピーを作り、タグ追加後のアプリで開いて元データの保持を検証する。自動移行が成立した場合はその結果を記録する。成立しない場合は、元ストアを消したり空のストアに置き換えたりせず、Migration Plan の案と影響を人間に提示して判断を求める。

## Human Decision

2026-10-05 に人間は Option A と本 ADR を最終承認した。Phase 3 要求・Acceptance Criteria 案も同日に承認した。状態管理方式を変える必要が出た場合は作業を止め、人間の判断を受ける。

2026-10-06、人間は [ADR-0007](0007-observation-ui-state.md) を承認した。一時的な四つの UI 状態の所有方式に限り、ADR-0007 が本 ADR の判断を置き換える。タグ、検索範囲、フィルタ、選択解除の判断は維持する。

## Consequences

- `Tag` と Note の関連、タグの保存失敗、旧ストアからのデータ保持をテストする。
- 検索語とフィルタは再起動後の復元対象にしない。検索結果と選択 ID の整合をテストする。
- 可変ウインドウ幅、Dark Mode、Dynamic Type、VoiceOver、キーボードで検索とタグ操作を確認する。
- 承認済みの Phase 3 要求に従い、タグ名の重複時には既存タグを再利用し、Phase 3 では改名と全体削除を設けない。
