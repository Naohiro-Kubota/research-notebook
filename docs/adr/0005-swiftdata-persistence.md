# ADR-0005: Project と Note の SwiftData 永続化方式

- Status: Accepted
- Date: 2026-10-05
- Decision Owner: Human

## Context

Phase 1 の `NotebookState` は Project と Note を値型の配列で保持し、アプリの再起動で消える。Phase 2 では、承認済みの [要求と Acceptance Criteria](../requirements/phase-2-swiftdata.md)に従い、Project と Note の所属関係と削除をローカルに永続化する。人間は 2026-10-05 に自動保存を選び、保存ボタンを置かないと決めた。

既存の 3 列 Navigation、必須タイトル、同名を許す識別子、入力中の画面反映は維持する。Phase 1 には移行すべき永続データがない。iCloud 同期や外部依存は対象外とする。

## Apple 公式情報・一次情報

| 資料 | URL | 確認日 | 公式資料から分かった事実 |
|---|---|---|---|
| Preserving your app’s model data across launches | https://developer.apple.com/documentation/swiftdata/preserving-your-apps-model-data-across-launches | 2026-10-05 | `@Model` で永続モデルを定義し、`ModelContainer` と `ModelContext` で保存する。`@Query` は View でモデルを取得する。テストにはメモリ上のコンテナを構成できる。 |
| ModelContext と autosaveEnabled | https://developer.apple.com/documentation/swiftdata/modelcontext ・ https://developer.apple.com/documentation/swiftdata/modelcontext/autosaveenabled | 2026-10-05 | メインコンテキストの自動保存は有効で、変更後や Scene・View のライフサイクル中に保存する。`save()` は未保存の変更を永続ストレージに書き込む。 |
| Defining data relationships with enumerations and model classes | https://developer.apple.com/documentation/swiftdata/defining-data-relationships-with-enumerations-and-model-classes | 2026-10-05 | `@Relationship(deleteRule: .cascade, inverse: ...)` は親の削除時に関連モデルを削除する。 |
| Adding and editing persistent data in your app | https://developer.apple.com/documentation/swiftdata/adding-and-editing-persistent-data-in-your-app | 2026-10-05 | Apple の例は、フォームの入力を一時状態に保持し、利用者が保存を選んでからモデルに反映する。その後のディスクへの書き込みには SwiftData の自動保存を使う。 |
| ModelContainer と SchemaMigrationPlan | https://developer.apple.com/documentation/swiftdata/modelcontainer ・ https://developer.apple.com/documentation/swiftdata/schemamigrationplan | 2026-10-05 | コンテナは対応可能なスキーマ変更を自動移行する。自動移行を超える変更には Migration Plan を指定できる。 |
| HIG: Modality | https://developer.apple.com/design/human-interface-guidelines/modality | 2026-10-05 | 一時的な編集画面を閉じると入力内容が失われる場合は、その状況を説明し、解決方法を提供する。 |

## Decision Drivers

- 自動保存という承認済みの利用者向け動作を、保存ボタンなしで実現する。
- Project を削除したときに所属 Note を残さない。
- SwiftUI と SwiftData の標準データフローを学び、不要な Repository や ViewModel を追加しない。
- 再起動後の復元、削除、保存失敗をテストできるようにする。
- 将来のスキーマ変更時に、保存データを失わない判断を行えるようにする。

## Options

### A. SwiftData モデルと Relationship を直接 View で利用する

Project と Note を `@Model` とし、Project から Note への Relationship に `.cascade` を指定する。アプリにローカルの `ModelContainer` を設け、View は `@Query` と環境の `ModelContext` を使う。選択状態は永続モデルとは分けて保持する。

**メリット**

- SwiftData の標準機能を利用でき、所属関係と連鎖削除を一か所で定義できる。
- Phase 1 の UI 構造を保ち、保存専用の層を追加せずに済む。
- メモリ上のテスト用コンテナと、再起動を模した再取得で振る舞いを検証できる。

**デメリット・リスク**

- 値型配列から参照型の永続モデルへ変えるため、Binding と選択状態の接続を見直す必要がある。
- 自動保存の時点は各入力直後のディスク書き込みを意味しない。保存失敗の検出と利用者への表示を実装時に確認する必要がある。
- Phase 1 の Note 本文入力を安定させる局所的な処理は、モデル更新方法が変わるため再検証が必要になる。

### B. 既存の値型 `NotebookState` を残し、SwiftData との変換層を設ける

View は引き続き `NotebookState` を使い、別の層が SwiftData モデルとの読み書きと同期を担当する。

**メリット**

- Phase 1 の View とモデル操作をより多く残せる。

**デメリット・リスク**

- 二つのデータ表現を同期する処理が必要になり、保存の時点と選択状態を追いにくい。
- 現時点では変換層が解決すべき具体的な問題を確認できていない。

## Proposed Decision

AI は A を提案する。Project と Note は別の永続モデルとし、Project の Note Relationship に `.cascade` を指定する。View は `@Query` から一覧を取得し、環境の `ModelContext` で作成と削除を行う。選択中の Project・Note は UI 状態として保持し、削除や Project 切替時に整合させる。画面上の変更は有効な入力へ即時反映し、自動保存を利用する。保存ボタンは置かない。

自動保存だけで「各入力が必ずディスクへ書き込まれた」と表示しない。保存失敗を検出して知らせる方法は実装前に検証し、失敗を成功扱いしない。テストではメモリ上のコンテナを使う Unit・Integration Test と、アプリ再起動を含む UI Test を組み合わせる。永続化によって UI Test 間でデータが残るため、テスト用の保存先を分離する。

Phase 2 は最初の永続スキーマを定義する段階であり、Migration Plan は作らない。今後、保存済みデータを持つスキーマを変更する際に、自動移行の可否とデータ保持方法を調査し、必要なら別 ADR で判断する。

## Human Decision

2026-10-05、人間は Phase 2 の Acceptance Criteria と「変更を自動保存し、保存ボタンは置かない」という利用者向け方針を承認した。同日、Option A と本 ADR を最終承認した。

外部依存、外部 API、破壊的なデータモデル変更、プライバシーに影響する設計が必要になった場合は別途検討する。

## Consequences

- ADR-0001 の SwiftUI ネイティブなデータフロー、ADR-0002 のテスト方式、ADR-0004 の Navigation 構造を維持する。
- Phase 1 のメモリ上のデータは再起動で消えるため移行しない。Phase 2 以降の保存データは、将来のスキーマ変更時に保持を検討する。
- 保存、連鎖削除、再起動後の復元、保存失敗時の表示を Acceptance Criteria と Definition of Done で確認する。
