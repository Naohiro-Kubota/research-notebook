# ADR-0008: Phase 4 の Web API 選定と Networking 境界

- Status: Accepted
- Date: 2026-10-06
- Decision Owner: Human

## Context

[Phase 4 の要求](../requirements/phase-4-web-api.md)では、公開 Web API で外部情報を検索し、結果を Research Item として保存する。人間は 2026-10-06 に Phase 4 の要求と Acceptance Criteria、および検索語の外部送信を許容した。同日、本 ADR の採用案を承認した。

初回の題材は文献メタデータ検索とする。これは API の種類を固定していなかった[プロダクト要求](../requirements/product-requirements.md)に対して承認された選択であり、一般の Web ページ全体を検索できるという意味ではない。iPadOS 17、Apple 標準 Framework、既存の 3 列 Navigation と SwiftData を前提とする。

## 一次情報

確認日: 2026-10-06。以下は提供元または Apple の資料から確認した事実であり、後述の採用案とは区別する。

| 資料 | 確認した事実 |
|---|---|
| [Crossref REST API](https://www.crossref.org/documentation/retrieve-metadata/rest-api/)、[Crossref の API 仕様](https://github.com/CrossRef/rest-api-doc/blob/master/README.md) | 公開 REST API は文献メタデータを JSON で返す。`/works` は `query.bibliographic` と `rows` を受け取る。対象は Crossref に登録された成果物であり、一般の Web 検索ではない。 |
| [Crossref: Access and authentication](https://www.crossref.org/documentation/retrieve-metadata/rest-api/access-and-authentication/) | Public 枠は登録・認証なしで使える。レートと同時実行の制限があり、超過時は HTTP 429 を返す。連絡先を付ける Polite 枠もある。 |
| [Crossref JSON format](https://github.com/CrossRef/rest-api-doc/blob/master/api_format.md)、[Crossref REST API](https://www.crossref.org/documentation/retrieve-metadata/rest-api/) | Work には DOI、DOI の URL、タイトル配列がある。著者など一部の項目は任意。抄録には出版社・著者の著作権が及ぶ場合がある。 |
| [OpenAlex: Authentication](https://help.openalex.org/api/authentication/)、[Search](https://help.openalex.org/api/searching/) | Works 検索があり、基本的な匿名利用もできる。利用量を増やすには API キーが推奨され、検索には利用量に応じた制限・料金体系がある。 |
| [Semantic Scholar Academic Graph API](https://api.semanticscholar.org/api-docs/graphs)、[API overview](https://www.semanticscholar.org/product/api) | 論文検索 API を公開している。公開アクセスには共有のレート制限があり、キー利用時は秘密情報の管理が必要になる。 |
| [URLSession](https://developer.apple.com/documentation/foundation/urlsession)、[HTTPURLResponse.statusCode](https://developer.apple.com/documentation/foundation/httpurlresponse/statuscode)、[JSONDecoder](https://developer.apple.com/documentation/foundation/jsondecoder) | `URLSession` の async API はデータと応答を返す。HTTP ステータスを読み、`Decodable` 型へ JSON をデコードできる。 |
| [Task.cancel()](https://developer.apple.com/documentation/swift/task/cancel%28%29)、[App Transport Security](https://developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity) | Task のキャンセルは協調的である。ATS は通常、`URLSession` の外部通信に HTTPS を要求する。 |

## Decision Drivers

- Phase 4 の HTTP、`Codable`、非同期処理、キャンセル、Network Test を学べること。
- API キーや新規外部ライブラリを必要とせず、秘密情報を Git に置かないこと。
- 検索結果に保存・再参照できる識別子と URL があること。
- 外部の応答形式を SwiftData モデルへ直接結合しないこと。
- 通信失敗、HTTP エラー、デコードエラー、キャンセル、保存失敗を混同しないこと。

## Options

### A. Crossref Public REST API

`/works?query.bibliographic=...&rows=...` で文献メタデータを検索する。

**利点:** 認証なしで開始でき、DOI と URL がある。Apple 標準 API だけで実装できる。

**欠点・制約:** Crossref 登録済みの成果物に範囲が限られる。レート制限があり、抄録を無条件に保存できない。登録されたメタデータの完全性と検索精度はアプリ側で保証できない。

### B. OpenAlex Works API

**利点:** 文献の広い探索と豊富なメタデータを扱える。

**欠点・制約:** 匿名利用は可能だが、利用拡大時にはキー・利用量・料金の判断が増える。Phase 4 の最小の学習題材としては管理項目が多い。

### C. Semantic Scholar Academic Graph API

**利点:** 論文検索と著者・抄録などの情報を扱える。

**欠点・制約:** 公開枠は共有レート制限を受け、安定した利用にはキー管理の検討が必要になる。

## Proposed Decision

AI は **Option A** を提案する。Phase 4 の検索対象を Crossref の文献メタデータに限定し、Public 枠と HTTPS を使う。連絡先をリポジトリへ固定せず、Polite 枠や有料枠は今回採用しない。検索は利用者の明示操作から始め、空白だけの語は送信しない。一度に少数の結果を取得し、429 を含む HTTP エラーを表示する。自動再試行・無限ページング・検索履歴は必要性が確認されるまで加えない。

Networking 境界は `URLSession` → Crossref 専用の `Decodable` DTO → 画面用の検索結果／保存用データとする。HTTP ステータスをデコード前に検証し、通信・HTTP・デコード・キャンセルを区別する。キャンセル後の古い応答で新しい検索状態を上書きしない。SwiftData のモデルを API DTO として使わない。新規ライブラリ、汎用 HTTP Framework、全画面共通の ViewModel／Repository は導入しない。実通信に依存しないテストのため、`URLSession` 設定または小さな注入点で応答を制御する。

検索語は HTTPS で Crossref へ送られる。人間はその外部送信を許容した。検索結果の抄録・全文は Phase 4 では保存しない。保存モデルの提案は [ADR-0009](0009-web-resource-persistence.md)に記す。UI 配置や重複保存の振る舞いは、この ADR だけでは決定しない。

## Human Decision

2026-10-06、人間は Option A と Proposed Decision の Networking 境界を承認した。

## Consequences and Verification

- API 利用条件、応答形式、レート制限は実装開始時に再確認する。
- 正常応答、空結果、HTTP 429・その他の非成功応答、不正 JSON、通信失敗、キャンセルと古い応答の抑止を実通信なしで検証する。
- ATS の例外、API キー、外部ライブラリを要することが判明したら、人間に影響と代案を提示する。
