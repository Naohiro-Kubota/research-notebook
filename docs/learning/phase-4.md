# Phase 4 学習ログ — Web API

記録日: 2026-10-07。承認済みの[要求](../requirements/phase-4-web-api.md)、[ADR-0008](../adr/0008-crossref-web-api-and-networking-boundary.md)、[ADR-0009](../adr/0009-web-resource-persistence.md)に基づく。人間による画面操作の確認が残っているため、Phase 4 全体の Definition of Done は未達。

## Apple 公式資料で確認した事実と適用

確認日: 2026-10-07。下表の中央列は公式資料の事実、右列はこのアプリでの判断である。

| 資料 | 公式資料の事実 | このアプリへの適用 |
|---|---|---|
| [URLSession](https://developer.apple.com/documentation/foundation/urlsession)、[HTTPURLResponse.statusCode](https://developer.apple.com/documentation/foundation/httpurlresponse/statuscode)、[JSONDecoder](https://developer.apple.com/documentation/foundation/jsondecoder) | 非同期の通信、HTTP ステータスの確認、JSON のデコードに利用できる。 | Crossref 専用 DTO へデコードし、保存モデルとは分けた。 |
| [Task.cancel()](https://developer.apple.com/documentation/swift/task/cancel%28%29) | Task のキャンセルは協調的に伝わる。 | 検索語の変更・画面終了時に Task をキャンセルし、識別子も照合して古い完了結果を捨てる。 |
| [ModelContainer](https://developer.apple.com/documentation/swiftdata/modelcontainer)、[Relationship](https://developer.apple.com/documentation/swiftdata/defining-data-relationships-with-enumerations-and-model-classes) | SwiftData でモデルを保存でき、Relationship に削除規則を指定できる。 | Project 所属の Web Resource に `.cascade` を指定し、旧ストアのコピーで移行を検証した。 |
| [Query](https://developer.apple.com/documentation/swiftdata/query) | 取得したモデルの変更を View に反映できる。 | Note 一覧の別セクションで保存済み Web Resource を観測する。 |
| [ContentUnavailableView](https://developer.apple.com/documentation/swiftui/contentunavailableview)、[ProgressView](https://developer.apple.com/documentation/swiftui/progressview)、[Link](https://developer.apple.com/documentation/swiftui/link) | 内容なし・検索失敗、進行中、URL への遷移に標準の View がある。 | 検索の空・エラー・読み込み、保存済み出典の参照に使用した。 |
| [HIG Search fields](https://developer.apple.com/design/human-interface-guidelines/search-fields)、[HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) | 検索範囲を伝える案内と可変ウインドウ幅、Dynamic Type とアクセシビリティの確認を勧める。 | ローカル Note 検索とは別画面にし、Crossref への送信と保存先 Project を明示した。外部通信は利用者の明示操作で開始する。 |

Crossref の `/works`、`query.bibliographic`、公開枠、Work の DOI・URL・タイトルは [Crossref REST API](https://www.crossref.org/documentation/retrieve-metadata/rest-api/) と [API 仕様](https://github.com/CrossRef/rest-api-doc/blob/master/README.md)に基づく。これは Apple の仕様ではない。

## 実装と学んだこと

- `URLComponents` で検索語をエンコードし、`URLSession` の応答を HTTP、通信、デコード、キャンセルに分けた。空の検索語は送信しない。タイトル・DOI・HTTPS URL が使えない Work と大文字小文字だけが異なる重複 DOI は結果から除いた。検索は明示操作の10件取得で、自動再試行・履歴・無限ページングは設けていない。
- 検索画面が `idle/loading/results/empty/error` と Task を所有する。検索語変更・画面終了時のキャンセルに加え、検索ごとの識別子で遅延応答の上書きを防ぐ。保存先 Project と検索語の外部送信を画面に示した。
- SwiftData に Web Resource 専用モデルを追加し、タイトル・DOI・出典 URL だけを保存する。同一 Project の同一 DOI は大文字小文字を無視して既存項目を返す。別 Project では保存できる。Note 一覧の独立した「Web Resources」セクションから標準 `Link` で出典を開く。Note の検索・タグ・選択状態は変更しない。
- Phase 3 の Project・Note・Tag で生成した合成ストアの**コピー**を新スキーマで開き、ID・本文・所属・共有 Tag と元ファイルの不変を確認した。fixture と生成手順は[記録](../../ResearchNotebookTests/Fixtures/README.md)に残した。任意の実ユーザーストアでの成功までは保証しない。

## 実装中の観測と判断

- iPadOS 17.2 Simulator では SwiftData 実体を `WebResource` と命名すると `Class 'nil' for entity 'WebResource'` の内部例外が出た。実体を `SavedWebResource`、コード上の型名を `WebResource` の型別名にすると、同じ属性と関係で保存・削除・移行テストが成功した。原因の一般化はしていない。これはこの環境での観測であり、Apple 公式資料の事実ではない。
- 読み取り専用ストアへの保存失敗後に `ModelContext.rollback()` すると、検証環境では検索シートが閉じた。追加した Web Resource だけを `delete(_:)` で取り消すと、画面と既存 Note を保持できた。計画上の「Contextをロールバック」からの局所的な変更で、保存失敗を成功表示しない要求を維持する。Swift Testing と UI Test で既存データの保持を確認した。
- Project の関係配列を直接読む Note 一覧では、シート内で保存した直後の新項目が画面へ反映されなかった。`@Query` で保存済み項目を観測し、選択中 Project のものをセクションに表示した。大量の保存件数で全件取得が問題になったら、Project ID で絞る FetchDescriptor を検討する。
- 外部検索の入口をツールバーへ追加すると、狭い幅で既存の「Noteを追加」が省略メニューに移った。タグフィルター行へ移し、既存操作への到達を保った。検索結果の保存失敗はテキストとアイコンで示し、色だけに依存しない。

## Acceptance Criteria と Definition of Done

| 項目 | 自動確認・コード確認 | 人間の実操作 |
|---|---|---|
| 明示検索と結果の DOI・タイトル・出典 | `CrossrefClientTests` と固定応答の UI Test で確認。実通信を常時テストには使わない。 | 未確認 |
| 読み込み・空・通信／HTTP／応答形式エラーと再試行 | クライアントのエラー分岐を Swift Testing、読み込み・空・HTTP エラー・再試行を UI Test で確認。 | 未確認 |
| 中断・変更後の古い結果の抑止 | 固定遅延応答の UI Test で確認。 | 未確認 |
| Project への保存、同一 DOI の再利用、再起動後の参照、保存失敗 | Swift Testing と UI Test で確認。既存の Project・Note・Tag の保持を移行 fixture と既存テストで確認。 | 未確認 |
| 可変幅、Dark Mode、Dynamic Type、VoiceOver、外部キーボード | 標準 SwiftUI の View とアクセシビリティラベルをコードで確認。画面・音声・入力の実操作は自動テストの対象外。 | 人間へ依頼済み、結果待ち |

2026-10-07 の最終確認: `scripts/build.sh` と `scripts/lint.sh` は成功。`scripts/test.sh` は Swift Testing 34件、XCTest UI Test 23件がすべて成功した。新規コンパイラ警告はない。Build に表示された「AppIntents.framework dependency がないため Metadata extraction を省略」は既存の通知である。検証中に一度 XCTest Runner が中断したが、該当テストの単独実行と後続の全件一括実行は成功した。手動確認の結果が届くまで、最後の Acceptance Criteria に含まれる Definition of Done は完了扱いにしない。

## 次Phaseで確認したいこと

- 保存件数が増えた場合の Project 別取得と一覧の性能。
- Phase 5 の可変ウインドウ幅に合わせた検索画面と3列 Navigation の配置。
