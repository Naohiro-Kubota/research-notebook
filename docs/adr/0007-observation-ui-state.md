# ADR-0007: Observation によるウインドウ単位の UI 状態管理

- Status: Proposed
- Date: 2026-10-06
- Decision Owner: Human

## Context

[Phase 3 ロードマップ](../learning/roadmap.md)は Observation と `@Observable` の学習を予定している。現在の [ADR-0006](0006-phase-3-tags-and-search-state.md) は、検索語、選択タグ ID、選択 Project ID、選択 Note ID を `ContentView` の個別の `@State` で所有する Option A を承認した。実装とテストは成立したが、明示的な `@Observable` 型による一時状態の所有と View 間データフローは学習できていない。

2026-10-06、人間は、現在の実装を前提にせず検討した「ウインドウごとに一つの Observable な UI 状態を所有し、SwiftData の永続モデルと分離する」設計提案を承認した。本 ADR は、その状態の範囲と既存判断との関係を記録する。製品要求、タグのデータモデル、Project 内検索、AND 条件、選択解除、iPadOS 17 の対象範囲は変更しない。

## Apple 公式情報・一次情報

確認日: 2026-10-06。以下は公式資料で確認した事実であり、後述のウインドウ単位という選択はこのアプリの設計判断である。

| 資料 | 公式資料で確認した事実 |
|---|---|
| [Observation](https://developer.apple.com/documentation/observation)、[`@Observable`](https://developer.apple.com/documentation/observation/observable%28%29) | `@Observable` マクロは型に変更追跡と `Observable` 準拠を追加する。プロトコルへの準拠だけでは変更追跡は追加されない。 |
| [Managing model data in your app](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app) | SwiftUI の Observation 対応は iPadOS 17 以降。View が読み取った Observable プロパティの変更を追跡する。Observable インスタンスの所有には `@State` を使用できる。 |
| [Model data](https://developer.apple.com/documentation/swiftui/model-data)、[`@Bindable`](https://developer.apple.com/documentation/swiftui/bindable) | 一時的な View 状態には `@State`、Observable 型の可変プロパティへの Binding が必要な場合には `@Bindable` を使用できる。 |
| [Preserving your app’s model data across launches](https://developer.apple.com/documentation/swiftdata/preserving-your-apps-model-data-across-launches) | SwiftData の `@Model` はモデルに `Observable` 準拠を追加し、`@Query` と SwiftUI の更新に統合される。 |

## Decision Drivers

- Phase 3 の Observation と `@Observable` を、実際の一時状態の所有と更新で学ぶ。
- 検索、タグフィルタ、Project・Note の選択を一つの情報源で扱い、既存の表示と選択解除を維持する。
- Project・Note・Tag の SwiftData 永続モデルに一時状態を混ぜず、保存スキーマを変更しない。
- 不要な ViewModel、Repository、Protocol、アプリ全体の共有状態を増やさない。
- 将来の複数ウインドウで、検索語と選択先を意図せず共有しない。

## Options

### A. ウインドウごとに `@Observable` な UI 状態を所有する

ウインドウのルート View が `@State` で一つの `@Observable` 型を所有する。その型に検索語、選択タグ ID、選択 Project ID、選択 Note ID と、それらに関する状態遷移を置く。子 View は同じインスタンスを受け取り、編集用 Binding が必要な箇所で `@Bindable` を使う。検索結果は SwiftData の Note と条件から導出し、状態型には保存しない。

**メリット**

- Observation の所有、読取追跡、Binding、状態遷移を一つの実用例で確認できる。
- 永続モデルと UI 状態の責務を分け、ウインドウ間の意図しない共有を避けられる。

**デメリット**

- 個別の `@State` より型と受け渡しが一つ増える。
- 選択解除の判定に必要な表示対象 ID を、SwiftData を読む View 側から状態型へ渡す境界を保つ必要がある。

### B. 個別の `@State` と Binding を維持する

現在の構成を維持し、SwiftData の `@Model` が提供する Observation を資料と実装で学ぶ。

**メリット**

- 変更と新しい型が不要。

**デメリット**

- `@Observable` 型の所有や `@Bindable` を使った UI 状態のデータフローを実践できない。

### C. アプリ全体で一つの Observable 状態を共有する

アプリのルートで一つの状態を所有し、すべてのウインドウへ渡す。

**メリット**

- 一つの状態インスタンスを渡せる。

**デメリット**

- 複数ウインドウで検索語と選択先が共有される。現時点でその製品要求はない。

## Proposed Decision

Option A を提案する。`@Observable` 型は Phase 3 の四つの一時状態だけを所有する。Project を選び直した場合と、検索・タグ条件・モデル変更で選択 Note が表示対象から外れた場合には、既存要求どおり詳細選択を解除する。Project を切り替えても検索語とタグ条件を維持する現行動作を保つ。状態型は SwiftData モデルや `ModelContext` を保持せず、選択解除の判定には View が導出した表示対象 ID を渡す。

シート表示、作成フォームの下書き、タグ入力など一つの View に閉じた状態は、その View の `@State` に残す。`NavigationSplitView` の列表示は既存 Navigation の振る舞いとして扱い、今回の四つの状態に機械的に統合しない。Project・Note・Tag は引き続き `@Model`／`@Query` を使用し、別の Observable 型へ複製しない。永続スキーマ、外部依存、非同期処理は変更しない。

本 ADR が承認された場合、ADR-0006 の Option A のうち「`ContentView` が四つの個別の `@State` を所有する」部分だけを本 ADR で置き換える。ADR-0006 のタグ、検索範囲、フィルタ、選択解除に関する判断は維持する。ADR-0001 の SwiftUI 標準データフローと必要最小限の抽象化という原則は維持する。

## Human Decision

2026-10-06、人間はウインドウ単位の Observable UI 状態という設計提案を承認した。本 ADR の最終承認は未了。

## Consequences

- `@Observable` 型の状態遷移を Swift Testing で検証し、検索・タグ・Project 切替・選択解除の既存 XCTest UI Test を回帰確認する。
- Build、Lint、Swift Testing、XCTest を実行し、関連する Phase 3 学習ログと実装計画を更新する。
- Simulator の手動操作が必要な確認は人間が行う。AI は自動テストの結果と人間の確認結果を区別し、未確認項目を完了扱いにしない。
- 実装調査でこの範囲を超える状態管理変更や要求変更が必要と分かった場合は、実装を止めて人間の判断を求める。
