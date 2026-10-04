# Phase 1: Notebook 基本 UI

承認日: 2026-10-04

## 背景

Project ごとに Note を整理し、iPad 上で一覧から編集へ進める基本操作を作る。SwiftData による永続化は Phase 2 で学ぶため、この Phase のデータはメモリ上で扱う。

## 承認済み要求

- Project と Note の項目はタイトルと本文。タイトルは必須。
- Project の一覧・作成・編集・削除を行う。
- 選択した Project の Note を一覧表示し、Note を作成・編集する。Note 単体の削除は Phase 2。
- 入力中の変更を画面上のデータへ即時反映する。永続化のための保存操作は Phase 2 で設ける。
- Project を削除したときは、その Project の Note も削除する。
- Navigation は Project 一覧、Note 一覧、Note 編集の 3 列を採用する。人間は 2026-10-04 に構成案と ADR-0004 を承認した。実機相当の幅での確認は実装後に行う。

## Acceptance Criteria

- [ ] 起動時、Project がなくても画面の意味と作成操作が分かる。
- [ ] 必須のタイトルを指定して Project と Note を作成できる。本文は空でもよい。
- [ ] Project の一覧から Project を選択すると、所属 Note の一覧を表示する。Note を選択すると、そのタイトルと本文を編集できる。
- [ ] Project と Note の有効なタイトル変更、および本文への入力が、関係する画面へ即時反映される。
- [ ] Project を削除すると所属 Note も削除され、削除済み項目の詳細や選択状態が残らない。キャンセルした場合は削除されない。
- [ ] 空白だけのタイトルでは Project と Note を作成できない。編集中にタイトルを空にした場合は理由が分かり、無効な変更が確定しない。
- [ ] アプリを再起動すると Phase 1 のデータは復元されない。永続化されたように見せる保存操作は設けない。
- [ ] iPad の全画面と狭いウインドウ幅で、Project 一覧から Note 編集まで移動し、戻れる。
- [ ] VoiceOver で一覧、選択、入力欄、削除の意味が分かる。Dynamic Type と Dark Mode で操作でき、色だけで状態を伝えない。主要操作にキーボードから到達できる。
- [ ] 変更したモデル操作の正常系・異常系、主要な UI フローを自動テストで検証し、Build、Lint、該当する Definition of Done を満たす。

## 設計上の詳細

- 必須タイトルの検証は前後の空白を除いた後の空文字を対象とする。作成時は有効なタイトルになるまで作成操作を無効にする。編集時の無効な入力は入力欄に表示して理由を示し、最後の有効なタイトルをデータに保持する。入力欄を離れたときは最後の有効なタイトルへ戻す。
- 同じタイトルの Project または Note は区別できる ID を持つ。タイトルの重複は禁止しない。
- Project を切り替えるとき、選択中の Note が移動先 Project に属さなければ Note の選択を解除する。
- Project 削除は所属 Note も失うことを確認画面で明示する。

## 対象外

- SwiftData と再起動後のデータ保持
- Note 単体の削除
- タグ、検索、外部 Web API、添付ファイル、複数ウインドウ
- Phase 5 で扱う Inspector などの追加レイアウト

## 関連資料

- [プロダクト要求](product-requirements.md)
- [学習ロードマップ](../learning/roadmap.md)
- [ADR-0001: SwiftUI データフロー](../adr/0001-native-swiftui-data-flow.md)
- [ADR-0002: テスト戦略](../adr/0002-testing-strategy.md)
- [ADR-0004: Navigation 構造案](../adr/0004-three-column-notebook-navigation.md)
