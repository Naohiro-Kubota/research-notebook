# ADR-0009: Phase 4 の Web Resource 保存モデル

- Status: Accepted
- Date: 2026-10-06
- Decision Owner: Human

## Context

[プロダクト要求](../requirements/product-requirements.md)は Research Item を Project 内の調査情報と定義し、将来 Note、Web Resource、Document、Image を扱う。[Phase 4](../requirements/phase-4-web-api.md)は検索結果を Research Item として保存する。一方、現行の SwiftData スキーマは `Project`、`Note`、`Tag` だけで、共通の Research Item モデルはない。Note は編集可能なタイトルと本文を持ち、Tag との関連がある。

人間は 2026-10-06 に Phase 4 の要求と Acceptance Criteria、および本 ADR の採用案を承認した。既存ストアの Project・Note・Tag を失わず、[ADR-0005](0005-swiftdata-persistence.md)の永続化方針と[ADR-0006](0006-phase-3-tags-and-search-state.md)の Note タグ範囲を守る。

## Apple 公式情報・一次情報

確認日: 2026-10-06。以下は Apple 資料の事実であり、モデルの形と削除規則は後述するアプリ固有の提案である。

| 資料 | 確認した事実 |
|---|---|
| [Preserving your app’s model data across launches](https://developer.apple.com/documentation/swiftdata/preserving-your-apps-model-data-across-launches) | `@Model`、`ModelContainer`、`ModelContext` でモデルを永続化できる。モデル間の属性から Relationship を表せる。 |
| [Defining data relationships with enumerations and model classes](https://developer.apple.com/documentation/swiftdata/defining-data-relationships-with-enumerations-and-model-classes) | Relationship には削除規則を指定できる。 |
| [ModelContainer](https://developer.apple.com/documentation/swiftdata/modelcontainer)、[SchemaMigrationPlan](https://developer.apple.com/documentation/swiftdata/schemamigrationplan) | 対応可能なスキーマ変更は自動移行され、自動移行を超える変更には移行計画を用意できる。今回の実ストアがそのまま移行できる保証ではない。 |

Crossref の Work に DOI・URL・タイトルがあることは[提供元の JSON 仕様](https://github.com/CrossRef/rest-api-doc/blob/master/api_format.md)で確認した。これは Apple の仕様ではない。

## Decision Drivers

- 保存した検索結果を Note と区別し、Project 内で再起動後も参照できること。
- API 応答の変更からローカル保存データを切り離すこと。
- 既存の保存データと Note の編集・タグ操作を壊さないこと。
- 将来の Research Item 全種類を先取りした抽象化を加えないこと。
- Project 削除時の所属データと保存失敗を明確に扱えること。

## Options

### A. Web Resource 専用の SwiftData モデルを追加する

`WebResource` を Project 所属の別モデルにし、検索結果から必要最小限の値を保存する。

**利点:** Note と Web Resource の意味を区別できる。API DTO を保存スキーマに流用せずに済む。既存の Note・Tag の属性を変えない。

**欠点・リスク:** 新しいモデル・Relationship・表示経路が必要。既存ストアの移行可否と Project 削除時の連鎖削除を検証する必要がある。

### B. 既存の Note にタイトルと DOI URL を本文として保存する

**利点:** 新規モデルを作らず、現在の Note 一覧と保存処理を使える。

**欠点:** 保存した文献と利用者が書いたメモをデータ上区別できない。URL と DOI が自由文に埋まり、後で識別・検証・リンク表示する際に解析が必要になる。Note の意味も変わる。

### C. 共通 Research Item モデルと種類別の下位モデルを一度に作る

**利点:** 将来の Note、Web Resource、Document、Image に共通の一覧や属性を設計できる。

**欠点:** Phase 7 以降の要求が未確定で、既存 Note の移行を含む大きなスキーマ変更になる。Phase 4 の成果には過剰である。

## Proposed Decision

AI は **Option A** を提案する。`WebResource` にローカルの識別子、所属 Project、タイトル、DOI、参照 URL を保存する。URL は Crossref が返す DOI URL を候補とし、抄録・全文・API 応答全体・検索語は保存しない。著者・発行年などを保存する必要が確認された場合は、項目と欠損時の表示を別途決める。現時点では共通 Research Item 型や Tag との関連を作らず、既存 Note モデルを変更しない。

Project を削除したときは所属 Web Resource も削除する `.cascade` を提案する。これは既存の Project → Note と同じ所属規則を Web Resource に適用するアプリ固有の判断である。API DTO から保存値を作る境界を置き、保存に失敗した場合は成功表示にしない。

実装前に Phase 3 版ストアのコピーで新スキーマを開き、既存 Project・Note・Tag の保持を確認する。自動移行が成立しなければ、元ストアを消去・置換せず、移行案を人間へ提示する。保存した同一 DOI を同一 Project で再度選んだ場合の振る舞いと、一覧・詳細での UI 配置は、要求を補足してから実装する。

## Human Decision

2026-10-06、人間は Option A と Proposed Decision のモデル、所属・削除規則、保存項目を承認した。同日、同一 Project・DOI の再保存では重複を防いで既存項目を表示し、保存済み Web Resource を Project 内の Note 一覧の別セクションへ表示することを決定した。

## Consequences and Verification

- Project への保存、再起動後の復元、Project 削除、保存失敗、旧ストアのデータ保持を検証する。
- Note の作成・編集・タグ操作を回帰確認する。
- Web Resource のタグ付け、添付、本文保存、汎用 Research Item への再編成は後続の要求と判断に委ねる。
