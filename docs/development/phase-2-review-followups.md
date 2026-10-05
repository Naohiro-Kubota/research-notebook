# Phase 2 レビューの継続課題

記録日: 2026-10-05。対象: [Phase 2 完了時の実装](https://github.com/Naohiro-Kubota/research-notebook/commit/288acfc)。人間は以下の4件を現時点で許容し、今後のリファクタリングで対策を検討すると決めた。いずれも未解決であり、今回の記録は要求や [ADR-0005](../adr/0005-swiftdata-persistence.md) を変更しない。着手時期と実装方法は未決定。

## P2-R1: 保存失敗時に編集内容を失う

- 重大度: 高
- 状態: 許容・未解決
- 根拠: [Note 編集](https://github.com/Naohiro-Kubota/research-notebook/blob/288acfc/ResearchNotebook/NoteEditorView.swift#L52-L62)と[Project 編集](https://github.com/Naohiro-Kubota/research-notebook/blob/288acfc/ResearchNotebook/ProjectFormView.swift#L63-L73)は保存失敗時に `rollback()` する。Apple の [`ModelContext.rollback()`](https://developer.apple.com/documentation/swiftdata/modelcontext/rollback%28%29) は未保存の変更を戻す。長文のペーストなど、一度に入力した内容を失う可能性がある。失敗時の長文入力は未検証。
- 対策の検討: 保存失敗時に入力を保持し、利用者が再試行または内容を退避できる方法を検討する。[HIG Modality](https://developer.apple.com/design/human-interface-guidelines/modality) のデータ損失に関する指針を確認する。
- 解決の確認: Note と Project の編集で、保存失敗後も入力内容を回復できることをテストする。

## P2-R2: 作成シートの終了で入力を失う

- 重大度: 中
- 状態: 許容・未解決
- 根拠: [Project 作成](https://github.com/Naohiro-Kubota/research-notebook/blob/288acfc/ResearchNotebook/ProjectSidebarView.swift#L48-L87)と[Note 作成](https://github.com/Naohiro-Kubota/research-notebook/blob/288acfc/ResearchNotebook/NoteListView.swift#L46-L85)はシート内の入力を作成操作まで一時状態に置く。シートのドラッグによる終了を制御していない。Apple は[シートをドラッグで閉じられる](https://developer.apple.com/documentation/swiftui/view/interactivedismissdisabled%28_%3A%29)と説明している。
- 対策の検討: 入力済みのシートを閉じる際に確認を求めるか、入力を保持する方法を検討する。[HIG Modality](https://developer.apple.com/design/human-interface-guidelines/modality) を参照する。
- 解決の確認: Project と Note のシートを入力後にドラッグで閉じ、内容を失わずに操作できることをテストする。

## P2-R3: 入力中の同期保存による遅延リスク

- 重大度: 中
- 状態: 許容・未解決
- 根拠: [Note 本文](https://github.com/Naohiro-Kubota/research-notebook/blob/288acfc/ResearchNotebook/NoteEditorView.swift#L58-L62)の変更ごとに、メインコンテキストで同期的な [`save()`](https://developer.apple.com/documentation/swiftdata/modelcontext/save%28%29) を呼ぶ。現行テストは文字の保持を確認したが、長文や遅い保存先での入力応答は測っていない。入力遅延は実測された不具合ではなくリスク。
- 対策の検討: 代表的な長文と連続入力で応答時間を測る。遅延が認められた場合は、承認済みの自動保存と失敗通知を保てる保存間隔・失敗検出方法を検討する。
- 解決の確認: 測定条件と結果を記録し、採用した保存方法で入力と失敗通知を検証する。

## P2-R4: 削除の保存失敗テストがない

- 重大度: 中
- 状態: 許容・未解決
- 根拠: [Note 削除](https://github.com/Naohiro-Kubota/research-notebook/blob/288acfc/ResearchNotebook/NoteEditorView.swift#L29-L43)と[Project 削除](https://github.com/Naohiro-Kubota/research-notebook/blob/288acfc/ResearchNotebook/ProjectFormView.swift#L31-L48)は保存失敗時にロールバックして警告する。一方、[読み取り専用保存先の UI Test](https://github.com/Naohiro-Kubota/research-notebook/blob/288acfc/ResearchNotebookUITests/ResearchNotebookUITests.swift#L14-L78)は作成・編集の失敗のみを検証する。削除失敗時の画面状態と再起動後のデータ保持は未検証。
- 対策の検討: Note と Project の削除失敗を再現するテストを追加する。
- 解決の確認: 失敗後に対象・他項目・選択状態が残り、再起動後も復元されることを確認する。

## 対応時の判断

- P2-R1 と P2-R3 は保存の時点と失敗後の状態を変える可能性がある。実装案を [承認済み要求](../requirements/phase-2-swiftdata.md) と ADR-0005 に照らす。矛盾が必要なら人間の判断を求める。
- 解決した項目は、再現手順、テスト結果、変更を行った PR を記録してから状態を更新する。
- この一覧は将来の作業予定を確定しない。Phase 2 の完了時に実施した Build・Test と操作確認の記録は [Phase 2 学習ログ](../learning/phase-2.md)に残す。
