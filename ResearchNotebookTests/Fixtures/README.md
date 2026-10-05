# Phase 2 旧ストアの検証用データ

`phase2.store` は実ユーザーデータを含まない合成データです。2026-10-05、Phase 2 のモデルを持つコミット `4c8875dcff3b33cfab008356cb49399d0178e70b` のアプリを Xcode 27 / iPadOS 17.2 Simulator で実行して生成しました。新しい Tag モデルや旧モデルの再定義から生成したストアではありません。

一時的な Swift Testing テストから `ModelContainer(for: Project.self, Note.self, configurations: ModelConfiguration(url: ...))` を作り、2 Project と各 2 Note を insert / save しました。生成テストを含む 9 テストが成功しました。

- Project の ID は `00000000-0000-0000-0000-000000000001` と `...002`。タイトルは `Project 1` / `Project 2`、本文は `Project body 1` / `Project body 2`。
- Note の ID の末尾は `011`、`012`、`021`、`022`。タイトルは `Note 1-1` など、本文は `本文 1-1` など。ID の十の位に対応する Project に所属します。

生成元の `default.store`、`default.store-wal`、`default.store-shm` は `/private/tmp/research-notebook-phase2-original/` に保持しました。Python の `sqlite3.connect("file:.../default.store?mode=ro", uri=True)` から SQLite の `backup` を使い、WAL 内の保存済みデータを含む単一ファイルのコピーを `phase2.store` に作成しました。生成元を移行・削除・置換していません。

`preservesPhase2StoreCopy()` は Bundle の fixture を一意な一時ディレクトリへコピーしてから新版コンテナで開きます。Project / Note の件数、ID、タイトル、本文、所属関係、空の tags と Tag 件数を照合し、Bundle 内の元ファイルのバイト列が変わっていないことも検証します。これはこの合成ストアでの自動移行の検証であり、任意の実ユーザーストアの移行成功を保証するものではありません。

確認した公式資料は [ModelContainer](https://developer.apple.com/documentation/swiftdata/modelcontainer)。対応可能なスキーマ変更の自動移行を説明しています。削除規則 `.nullify` の既定値と iOS 17 の Availability は Xcode 27 の SwiftData SDK interface でも確認しました。Tag の optional な `notes` に `.nullify` と `inverse: \Note.tags` を付け、Note の `tags` は通常の配列にしています。既存の Project → Note の `.cascade` は変更していません。

## Relationship 候補の検証

確認環境は Xcode 27 / iPadOS 17.2、iPad Pro 11-inch 4th generation（UDID `33CA3AC8-9A60-42F4-A25A-14DBF86375DA`）。候補は一時的な別 Scheme から既存の `-uiTestingStoreID` と一意な UUID を渡して隔離しました。候補ごとの定義・Scheme・実行ログを `/private/tmp/task1-schema-candidates/` に保存しました。中間スキーマの保存先も削除・置換していません。

| 候補 | Note.tags | Tag.notes | 結果 |
|---|---|---|---|
| mandatory-inverse | `[Tag] = []` | `[Note] = []`、nullify、inverse | 共有の保存・再取得と Note 削除は成功。条件付き Project 削除が memory/disk ともエラー 134050。 |
| optional-note-tags | `[Tag]? = []` | `[Note] = []`、nullify、inverse | 同じ Project 削除エラー。 |
| optional-both | `[Tag]? = []` | `[Note]? = []`、nullify、inverse | 共有の保存・再取得、Note 削除、条件付き Project 削除、旧ストアコピー移行が成功。 |
| optional-tag-notes-only（採用） | `[Tag] = []` | `[Note]? = []`、nullify、inverse | 同じ検証が成功。Note.tags の optional 化は不要。 |

失敗メッセージは `Constraint trigger violation: Batch delete failed due to mandatory MTM nullify inverse on Note/tags`。実アプリと同じ `delete(model: Project.self, where: ...)` の失敗を、`Tag.notes` の optional 化だけで解消したのが実測結果です。初期の逆参照なし候補では共有関係のディスク再取得が失敗したため採用しませんでした。

Apple 公式の [Relationship の定義と削除規則](https://developer.apple.com/documentation/swiftdata/defining-data-relationships-with-enumerations-and-model-classes) と [nullify](https://developer.apple.com/documentation/swiftdata/schema/relationship/deleterule-swift.enum/nullify) は、削除したモデルへの関連先からの参照を nullify することを説明しています。これは公式情報です。今回の mandatory な多対多の逆関係と条件付き cascade の組合せで発生した制約エラー、optional な `Tag.notes` での解消は、このプロジェクトの Simulator 検証から得た事実です。公式資料だけでこの組合せの成功を保証したとは扱いません。

## 最終検証

- `scripts/build.sh` 成功。Phase 2 のビルドログにも記録されていた AppIntents metadata extraction skipped のツール警告以外、新規コンパイラ警告なし。
- `scripts/lint.sh` と `git diff --check` 成功。
- `SIMULATOR_UDID=33CA3AC8-9A60-42F4-A25A-14DBF86375DA scripts/test.sh` 成功。Swift Testing 12 テスト（共有・Note 削除・Project 削除は各 memory/disk 2 ケース）、既存 XCTest UI 15 テスト、失敗 0。
- 最終ログは `/private/tmp/task1-final-build.log`、`/private/tmp/task1-final-lint.log`、`/private/tmp/task1-final-all-tests.log`。xcresult は Worktree 内 `DerivedData/Logs/Test/Test-ResearchNotebook-2026.10.05_23-44-29-+0900.xcresult`。
- fixture の SHA-256 は `6b730019f625c8ec0400597bd75b32dcdff1998e312807a873d7a50bece41a0f`。検証後も変わっていません。

これは Task 1 のスキーマとデータ保持の記録です。タグ名・付与操作、検索 UI、Phase 3 全体の HIG / Accessibility 確認は後続 Task の対象です。
