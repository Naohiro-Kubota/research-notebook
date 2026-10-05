# Phase 3 学習ログ — アプリ状態と検索

確認日: 2026-10-05。Task 1（Tag スキーマと旧ストアのデータ保持）の結果を記録する。Phase 3 全体は未完了。

## Apple 公式資料で確認した事実

| 資料 | 公式資料の事実 | このアプリへの適用 |
|---|---|---|
| [Defining data relationships with enumerations and model classes](https://developer.apple.com/documentation/swiftdata/defining-data-relationships-with-enumerations-and-model-classes) | SwiftData はモデル間の Relationship を管理し、削除規則を指定できる。 | Note と共有 Tag に双方向の Relationship を設けた。 |
| [ModelContainer](https://developer.apple.com/documentation/swiftdata/modelcontainer) | 対応できるスキーマ変更は自動移行し、それを超える変更には `SchemaMigrationPlan` を指定できる。 | Phase 2 ストアのコピーを新スキーマで開き、データ保持を検証した。 |
| [Relationship.DeleteRule.nullify](https://developer.apple.com/documentation/swiftdata/schema/relationship/deleterule-swift.enum/nullify) | 関連モデルを削除したとき、残るモデルから削除済みモデルへの参照を取り除く。 | Tag を残したまま Note を削除する関係に採用した。 |

## Task 1 の実装と実測

- `Tag` を独立した SwiftData `@Model` とし、`Note.tags` と `Tag.notes` を逆関係にした。すべてのアプリ用 `ModelContainer` に Tag を登録した。Project と Note の既存フィールド、および Project から Note への `.cascade` は変更していない。
- iPadOS 17.2 Simulator のメモリ内・ディスク保存先で、一つの Tag を別 Project の Note と共有し、別コンテキストから再取得した。Note 単体削除と本番と同じ条件付き Project 削除で、Note が消え、共有 Tag と未使用 Tag が残ることを確認した。
- `Tag.notes` が必須配列の場合、タグ付き Note を含む Project の条件付き削除が `NSCocoaErrorDomain 134050` で失敗した。`Tag.notes` を optional 配列にすると同じテストが成功した。これは上記 Simulator の実測であり、Apple 公式資料にこの組合せの動作保証があるという意味ではない。候補とログは [旧ストア fixture の記録](../../ResearchNotebookTests/Fixtures/README.md)に残した。
- Phase 2 モデルで作った合成ストアの**コピー**を新版で開き、2 Project、4 Note の件数、ID、タイトル、本文、所属関係が一致し、タグが空であることを確認した。元 fixture のバイト列も変わっていない。任意の実ユーザーストアや別 OS 版の移行成功まで保証する検証ではない。

## Task 1 の Definition of Done

- 承認済み [要求](../requirements/phase-3-app-state-and-search.md)と [ADR-0006](../adr/0006-phase-3-tags-and-search-state.md)のうち、Task 1 が担当する共有 Tag、削除後の保持、旧ストアのデータ保持を満たした。タグ名規則・付与 UI・検索は後続 Task の対象。
- `scripts/build.sh`、`scripts/lint.sh`、`git diff --check` は成功。Swift Testing 12 件と XCTest UI Test 15 件が iPadOS 17.2 Simulator で成功した。新規 Swift コンパイラ警告はない。AppIntents メタデータ抽出省略の既存ツール警告のみ確認した。
- 新規 UI はない。Phase 3 の可変幅、Dark Mode、Dynamic Type、VoiceOver、キーボードの操作確認は、タグ操作と検索 UI が入る後続 Task で行う。Phase 3 全体の Definition of Done は未達。
