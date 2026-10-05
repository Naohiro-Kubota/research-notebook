# Phase 2: SwiftData による永続化

要求・Acceptance Criteria 承認日: 2026-10-05（Asia/Tokyo）

## 背景

Phase 1 の Project と Note はメモリ上にあり、アプリの再起動で消える。Phase 2 では両者をローカルへ永続化し、Note 単体の削除を追加する。

## 承認済み要求

- Project と Note のタイトル、本文、所属関係を SwiftData でローカルに保存する。
- Project の削除時には所属 Note も永続的に削除する。
- Note を単体で削除できるようにする。
- 有効な変更は自動保存する。保存ボタンは置かない。保存前にアプリが終了した場合も、正常に保存された変更は次回起動時に復元する。保存失敗時に成功したと誤認させない。
- Phase 1 の必須タイトル、同名を許す ID、画面上の即時反映、3 列 Navigation を維持する。

## Acceptance Criteria

- [ ] Project と Note の作成・編集結果を保存後、アプリを終了・再起動しても、タイトル、本文、所属関係が復元される。
- [ ] Note は所属 Project の一覧にだけ表示される。同名の項目も別の項目として扱える。
- [ ] Note を単体で削除できる。キャンセル時は残り、削除確定後は再起動しても復元されない。選択中なら詳細表示を解除する。
- [ ] Project を削除すると所属 Note も削除され、再起動後にも残らない。他の Project と Note は残る。
- [ ] 空白だけのタイトルは保存されない。保存失敗時は失敗を知らせ、成功したように表示しない。
- [ ] 変更は自動保存され、保存ボタンは表示されない。正常に保存された変更は、保存ボタンを押さずにアプリを終了しても次回起動時に復元される。
- [ ] 永続化の正常系・失敗系と主要 UI フローを自動テストで検証し、Build、Lint、該当する Definition of Done を満たす。

## 設計時に確認する事項

- SwiftData の自動保存の時点と保存失敗の検出・表示方法。自動保存は各キー入力直後のディスク書き込みを保証する、という要求にはしない。
- Note の選択状態を削除や Project 切替後に整合させる方法。
- Phase 1 の `NoteBodyEditor` にある入力中の再評価を抑える処理が、SwiftData 移行後にも必要かどうか。
- iPadOS 17 で採用する API の Availability。

## 対象外

- Phase 1 のメモリ上のデータを移行する処理。再起動で消えるため、移行元の永続データはない。
- iCloud 同期、外部 API、外部依存、タグ、検索、添付ファイル、複数ウインドウ。
- 将来のスキーマ変更を先取りした Migration Plan の実装。

## 関連資料

- [学習ロードマップ](../learning/roadmap.md)
- [Phase 1 要求](phase-1-notebook-basic-ui.md)
- [ADR-0001: SwiftUI データフロー](../adr/0001-native-swiftui-data-flow.md)
- [ADR-0002: テスト戦略](../adr/0002-testing-strategy.md)
- [ADR-0004: Navigation 構造](../adr/0004-three-column-notebook-navigation.md)
- [ADR-0005: SwiftData 永続化方式](../adr/0005-swiftdata-persistence.md)
