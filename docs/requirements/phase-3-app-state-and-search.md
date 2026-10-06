# Phase 3: アプリ状態と検索

承認日: 2026-10-05（Asia/Tokyo）。人間は以下の要求と Acceptance Criteria を承認した。

## 背景

[ロードマップ](../learning/roadmap.md)の Phase 3 は、タグ、ローカル検索、フィルタ、選択状態を扱う。現行アプリに Research Item の共通モデルはなく、Project と Note を SwiftData で保存している。3 列の Navigation と既存データを維持する。

## 承認済み要求

- Note に複数のタグを付け、同じタグを複数の Project に属する Note で再利用できる。Phase 3 では Note 以外の Research Item は扱わない。
- 選択中の Project に所属する Note のタイトルと本文をローカル検索する。検索範囲を画面上で示す。
- 一つのタグで Note を絞り込める。検索語とタグの両方がある場合は、両方に一致する Note を表示する。
- 絞り込みで選択中の Note が一覧から外れたら詳細選択を解除する。Note のデータは変更しない。
- 検索語、タグフィルタ、選択 ID は一時的な UI 状態とし、Project、Note、タグの内容は永続化する。
- タグ名は前後の空白を除いて保存し、空白だけを拒否する。大文字と小文字だけが異なる名前は同じタグとして扱い、既存タグを再利用する。Phase 3 ではタグ名の変更と全体からの削除は設けず、Note からの解除を提供する。未使用のタグは再利用のために残す。

## Acceptance Criteria

- [x] Note にタグを追加・解除できる。同じタグを別の Note に付けられ、アプリ再起動後も関連が復元される。
- [x] 空白だけのタグを作れない。前後の空白や大文字・小文字だけが異なる入力から重複タグを作らない。
- [x] 既存の Project と Note を保存した旧版ストアを新版で開き、タイトル、本文、所属関係を失わない。
- [x] 選択中の Project の Note をタイトルと本文で検索できる。入力すると結果が更新され、検索語を消すと全件へ戻る。他 Project の Note は結果に出ない。
- [x] 一つのタグによる絞り込みと検索語を併用できる。条件がないときは選択中の Project の全 Note を表示する。
- [x] Note が存在しない場合と条件に一致する Note がない場合に、それぞれ意味が分かる表示をする。
- [x] 条件変更、Project 切替、削除で選択中の Note が表示対象から外れたら、詳細選択を解除する。保存済み Note は絞り込みによって削除されない。
- [x] タグの保存に失敗した場合は成功として表示しない。既存の作成・編集・自動保存の振る舞いを維持する。
- [ ] タグの永続化と検索・絞り込み・選択の正常系と主要な異常系を自動テストで確認し、[Definition of Done](../development/definition-of-done.md)を満たす。

## 対象外

- Project を横断する検索、Spotlight 連携、外部 API。
- 検索履歴、候補、複数タグを同時に指定するフィルタ。
- Note 以外の Research Item へのタグ付け。
- タグ名の変更と、タグを全 Note から削除する操作。
- Phase 2 の[継続課題](../development/phase-2-review-followups.md)全体の解消。

## 関連 ADR

- [ADR-0001: SwiftUI データフロー](../adr/0001-native-swiftui-data-flow.md)
- [ADR-0004: 3 列 Navigation](../adr/0004-three-column-notebook-navigation.md)
- [ADR-0005: SwiftData 永続化](../adr/0005-swiftdata-persistence.md)
- [ADR-0006: Phase 3 のタグと検索状態](../adr/0006-phase-3-tags-and-search-state.md)
