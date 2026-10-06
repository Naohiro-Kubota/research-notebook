# Phase 4: Web API

承認日: 2026-10-06（Asia/Tokyo）。人間は以下の要求と Acceptance Criteria、および検索語の外部送信を承認した。Web API の種類、保存モデル、詳細な UI と重複保存の振る舞いは別途判断する。

## 背景

[ロードマップ](../learning/roadmap.md)の Phase 4 は、公開 Web API による外部情報検索、Loading / Empty / Error 表示、検索結果から Research Item への保存を扱う。既存の Project・Note・Tag、3 列 Navigation、iPadOS 17 を維持する。現行アプリに Research Item 共通モデルはない。

## 承認済み要求

- 外部の公開 Web API から研究対象を検索できる。
- 検索中、結果なし、エラーを利用者に区別して表示する。
- 検索結果を Project 内の Research Item として保存し、再起動後も参照できる。
- 利用者が入力した検索語を選定する Web API へ送信することを許容する。秘密情報をソースコード・Git に保存しない。
- 既存の Project・Note・Tag と保存データを失わない。

## Acceptance Criteria

- [ ] 検索語を入力して外部情報を検索でき、結果の出典と保存に必要な情報を確認できる。
- [ ] 検索中、該当なし、通信・サーバー・応答形式のエラーを区別して表示する。エラー時には再試行できる。
- [ ] 検索を中断・変更した場合、古い結果が新しい検索結果として表示されない。キャンセルを通常のエラーとして表示しない。
- [ ] 選んだ結果を指定 Project に保存でき、再起動後も参照できる。保存失敗を成功として表示しない。既存の Project・Note・Tag を失わない。
- [ ] 正常応答、HTTP エラー、不正 JSON、通信失敗、キャンセル、保存と再読込を自動テストで確認し、[Definition of Done](../development/definition-of-done.md)を満たす。

## 未決定事項

- Web API と検索対象の分野、保存する項目。候補は [ADR-0008](../adr/0008-crossref-web-api-and-networking-boundary.md)。
- Research Item の保存モデルと Project 削除時の規則。候補は [ADR-0009](../adr/0009-web-resource-persistence.md)。
- 同じ外部情報を同じ Project へ再度保存した場合の振る舞い。
- 外部検索の配置と、保存済み Research Item の一覧・詳細表示。

## 対象外

- ユーザーアカウント、独自バックエンド、複数端末同期、課金、AI/LLM 機能。
- Web ページの全文取得、PDF 取り込み、添付ファイル、外部 API への書き込み。
