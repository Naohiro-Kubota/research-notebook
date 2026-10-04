# Phase 1 学習ログ — Notebook 基本 UI

初回確認日: 2026-10-04。追加検証・修正日: 2026-10-05。最大 Dynamic Type の連続本文入力の文字欠落を修正・検証した。可変幅・VoiceOver・キーボード到達性に未確認項目があるため、Phase 全体の Definition of Done は未達。

## 学習した概念と設計判断

- `ContentView` の `@State` が値型の `NotebookState` を所有し、子 View へ Binding を渡す。ViewModel や Repository は追加しない（ADR-0001）。
- Project と Note は UUID で関連付け、同名でも区別する。モデル操作が必須タイトルと選択の整合性を守る。
- `NavigationSplitView` の sidebar / content / detail に Project / Note / 編集を配置する（人間が承認した ADR-0004）。Note 選択時には編集領域を確保するため先行列の表示を切り替える。3 列が常時並ぶという意味ではない。
- 作成時は無効タイトルで作成を無効にする。編集時は入力欄の draft と最後の有効なモデル値を分け、フォーカスを離れた時に戻す。無効状態の説明は文言を使う。
- Note 本文の入力は小さな `NoteBodyEditor` の `@State` に保持し、`onChange` でモデルへ即時反映する。親モデル更新による入力Viewの再評価を `equatable()` で抑える。具体的に観測した文字欠落への修正であり、全Viewへ適用する方針ではない。保存ボタンはなく、データは再起動で消える。SwiftData は Phase 2。
- Swift 6 言語モード、Swift Testing のモデルテスト、XCTest の主要 UI フローを使用する（ADR-0002）。外部依存は追加しない。

## Apple 公式資料

確認日はいずれも 2026-10-04。以下は公式資料の事実であり、上の実装方針はプロジェクトの判断。

| 公式資料 | 確認した事実 | 適用 |
|---|---|---|
| [NavigationSplitView](https://developer.apple.com/documentation/swiftui/navigationsplitview) | 2・3 列を構成でき、先行列の選択が後続列へ反映される。iPad の Slide Over のような狭い環境ではスタックへ折りたたまれる。 | 標準 Navigation を使う。実際の幅変更の成功は資料だけから推定しない。 |
| [HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) | 大きな文字、複数の伝達手段、システムの支援機能への対応を勧め、Accessibility Inspector による監査を案内している。 | 標準コントロール、入力欄のラベル、選択 trait、無効入力の文言を使う。VoiceOver 実操作は別途確認する。 |
| [HIG Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode) | システムの外観設定を尊重し、両外観の読みやすさを確認する。外観へ適応する semantic color を勧める。 | 固定色を追加せず標準の色と secondary を使用し、Dark Mode の確認を行う。 |

追加確認日 2026-10-05: [EquatableView](https://developer.apple.com/documentation/swiftui/equatableview) は新旧の値を比較し、等しければ子の更新を防ぐ（公式事実）。本アプリでは Note ID で入力Viewを比較する（設計判断）。Phase 1 は同じ本文への書き手がその入力欄だけで、選択した Note が変わると外側の `.id(noteID)` が入力状態を作り直す。Phase 2 で別の書き手や外部更新を導入する際は、この同値性の条件を再検討する。[typeText](https://developer.apple.com/documentation/xcuiautomation/xcuielement/typetext(_:)) は文字列入力、[typeKey](https://developer.apple.com/documentation/xcuiautomation/xcuielement/typekey(_:modifierflags:)-9ubn) は物理キーと修飾キーの入力に用いる。[UIPasteboard.general](https://developer.apple.com/documentation/uikit/uipasteboard/general) はシステムの汎用ペーストボードを取得する。UIテストではSimulator内に既知のテスト文字列を用意し、標準Pasteメニューから入力する。

NavigationSplitView は公式 Markdown、HIG は Apple 配信の `tutorials/data/design/human-interface-guidelines/{accessibility,dark-mode}.json` の本文で確認した。通常のページ取得が JavaScript 要求だけを返したため、この公式本文を利用した。

## 検証環境と結果

Xcode 27.0、iPadOS 17.2 の iPad Pro (11-inch) (4th generation)、UDID `33CA3AC8-9A60-42F4-A25A-14DBF86375DA`。Build/Test は専用 Worktree で実行した。

| 検証 | 結果・証拠の範囲 |
|---|---|
| Build / Lint | `scripts/build.sh`、`scripts/lint.sh` 成功。Swift コンパイラの新規警告なし。既知の App Intents metadata extraction skipped 警告は残る。 |
| 全自動テスト | 修正後のLight / largeでSwift Testing 7 件、UI Test 9 件が成功（失敗 0）。モデルの正常・異常系、作成・編集・キャンセル・削除・選択解除、連続入力、ペーストとモデル反映を検証。 |
| 連続入力 | `testContinuousBodyInputAndRelaunchClearsData` で複数行57文字を1回の `typeText` で入力し、全文一致を確認。文字ごとの待機なし。修正後の最大 Dynamic Type / Dark Mode で3回反復成功。 |
| ペーストとモデル反映 | `testBodyPasteSurvivesProjectSwitch` で標準Pasteメニューから複数行57文字を入力し、別Projectへ移動した後に元のNoteを選び直して全文一致を確認。入力欄の状態だけでなく、モデルへ反映された本文を読み直している。 |
| 再起動 | 同テストで Project と Note を作成後、terminate / launch し、Project 空状態・行なし・本文欄なしを確認。 |
| 全画面操作 | 上記 iPad の通常 Simulator ウインドウで Project → Note → 編集を UI Test で確認。実際の狭いアプリウインドウへの変更は未確認。 |
| Dark Mode / 最大 Dynamic Type | 修正後の連続本文入力、ペースト・Project切替、Project編集の3テストが成功。Note編集画面の保存画像を目視し、タイトル・本文の折り返しと操作領域を確認。全UIの目視確認ではない。 |
| 色以外の意味 | ソース確認: 必須タイトルの説明、無効入力の文章、削除確認の文章、選択の accessibility trait を使用。実際の読み上げは未確認。 |

追加の画像・AX 確認には iPadOS 27.0 の iPad Pro 13-inch (M5) を使用した。標準文字サイズと Dark Mode / `accessibility-extra-extra-extra-large` の空状態を `simctl io screenshot` で確認し、説明文の折り返しと外観への適応を観測した。空状態の画像だけで編集画面の操作性を合格とはしない。Device Hub の AX ツリーで空状態、Project タイトル入力、本文ラベルを観測し、⌘⇧N で Project 作成画面が開くことを確認した。

### 追加確認結果

Dark Mode と最大 Dynamic Type の設定で、Project 作成・編集は成功した。一方、Note の連続本文入力は全文一致せず失敗し、再実行でも再現した。入力結果の一例は `Contiuos iptkeeps everychrctr.Second paragraph.` で、期待した57文字から文字と改行が欠落した。標準サイズの成功を最大サイズへ広げて扱わない。

初回調査では Note 本文をローカル `@State` へ変更しただけでは再発したため撤回した。2026-10-05 に追加の切り分けを実施した。

| 同じ最大 Dynamic Type / Dark Mode / 57文字の入力 | 結果 |
|---|---|
| モデルを持たない単独 `TextEditor`（調査用画面） | 成功。 |
| 同じ3列画面で本文のモデル書き込みだけを止めた `TextEditor` | 3回とも成功。 |
| 本文入力Viewを分離し、モデルへの即時反映を維持しながら親更新による再評価を `equatable()` で抑える | 3回とも成功。 |
| 修正後の通常アプリで連続入力・ペーストとモデル読み直し・Project編集 | 3テスト成功。 |

この比較から、モデル更新による入力Viewの再評価が高速入力へ干渉していたと推測し、その経路を抑える局所的な修正を採用した。SwiftUI内部で失われたイベント自体は観測しておらず、正確な内部原因まで断定しない。調査用画面とモデル書き込み停止は撤去した。元の1回の連続入力テストを保持し、文字ごとの待機で失敗を隠していない。

物理 `typeKey` の追加実験は日本語IMEによる変換が発生し、ASCII文字列と一致しなかった。これは連続入力の文字欠落と同じ事象とは扱わない。通常の人間の速度での入力と日本語IMEの変換・確定は人間の実操作で確認する。ペーストはホスト側のCUA経路では反映されなかったが、Simulator内のテスト用UIPasteboardと標準Pasteメニューでは全文一致し、Project切替後も保持された。

編集画面の証拠は `Test-ResearchNotebook-2026.10.05_00-01-33-+0900.xcresult` の `Note editor after multiline paste` 添付画像を確認した。iPadOS17.2 / 最大文字サイズ / Dark Mode で、大きいタイトルと複数行本文が読みやすく折り返されていた。toolbarの操作は省略記号メニューへまとまるため、キーボードのみの到達性は別途確認する。

再現手順は `simctl ui <UDID> appearance dark` と `simctl ui <UDID> content_size accessibility-extra-extra-extra-large` を設定し、`testContinuousBodyInputAndRelaunchClearsData` を実行する。Project / Note 作成後の本文欄に1回の `typeText` で入力した結果が全文と一致するか比較する。調査終了後は light / large へ戻した。テストはシステム設定を変更しないため、設定条件を記録して実行する。

### 観測できなかった項目

- 狭い・中間ウインドウ幅での列の折りたたみ、前の階層へ戻る操作。Device Hub の screenshot API が利用できず、幅変更のネイティブ操作を確実に観測できなかった。Mac 側の表示倍率変更は iPad アプリの幅変更の代用にしない。
- VoiceOver の有効化、フォーカス順、一覧・選択・入力・削除の読み上げ。AX のラベル確認を VoiceOver 合格と扱わない。
- キーボードだけでの Project 選択、Note 選択、入力、作成確定、編集、削除、戻る操作への到達。Project 作成ショートカットのみ部分確認。XCTest の文字入力はキーボード到達性の代用ではない。
- 物理キー試験では日本語IMEの変換に加え、⌘Nの後にNote作成の入力欄が現れない試行もあった。入力経路やフォーカスとの切り分けができていないため、ショートカットの全環境での成功とはしない。
- 通常速度での人間の実入力、日本語IMEの変換・確定。標準Pasteメニューからの複数行ペーストは追加テストで確認済みだが、人間のキー入力速度やIMEの代用にはしない。

これらは人間の iPad / Simulator 操作による確認が必要。新規機能や構造変更で回避せず、観測結果を得てから必要な修正を判断する。

### 人間に確認を依頼する実操作

人間の確認結果はまだ取得していない。以下の結果と端末 / OS / 幅 / 入力方式を追記するまでは Phase 1 の DoD を満たさない。

1. 全画面から中間幅、狭い幅へ変更し、Project一覧 → Note一覧 → 編集と、戻る操作で各一覧へ移動する。選択Project / Noteが分かり、編集内容が残ることを確認する。
2. 各幅でProject削除をキャンセルした場合は残り、確定した場合は所属Noteと選択詳細が消えることを確認する。
3. VoiceOverを有効にし、一覧の名称・選択状態、必須タイトル・本文入力、無効タイトルの理由、所属Noteも失う削除確認を読み上げで確認する。
4. 物理キーボードとFull Keyboard Accessを使い、追加・選択・作成確定・入力・編集・削除・戻るへタッチなしで到達する。⌘⇧N / ⌘Nと、大きい文字で省略記号メニューへ入った操作も確認する。
5. 通常の速度で英文と日本語IMEの変換・確定、複数行ペーストを行い、Projectを切り替えて戻っても全文が一致することを確認する。Dark Mode / 最大Dynamic Typeの編集画面で見切れや到達不能がないことを確認する。

## Acceptance Criteria の照合

| 要求 | 状態・対応する証拠 |
|---|---|
| 起動時の意味・作成操作 | 自動確認: 起動空状態と追加ボタン。 |
| 必須タイトルで Project / Note 作成、空本文可 | 自動確認: モデルテストと作成 UI Test。 |
| 選択 Project の Note 表示・Note 編集 | 自動確認: Note 作成編集、Project 切替 UI Test。 |
| 有効タイトル・本文の即時反映 | 自動確認: モデル更新、Project / Note 編集 UI Test、連続本文入力。 |
| Project 削除で所属 Note・選択解除、キャンセル | 自動確認: モデル削除、UI の削除とキャンセル。所属 Note の UI 削除後表示はモデル検証で補完。 |
| 空白作成拒否、無効編集の説明・非確定 | 自動確認: モデル異常系、Project / Note の UI Test。 |
| 再起動非復元・保存操作なし | 自動確認: 再起動テスト。保存操作なしはソース確認。 |
| 全画面・狭い幅で編集まで移動して戻る | 部分確認: 全画面主要フローのみ。狭い幅と戻る操作は未確認。 |
| VoiceOver / Dynamic Type / Dark Mode / 色 / Keyboard | 部分確認。VoiceOver とキーボード全経路は未確認。 |
| 自動テスト・Build・Lint・DoD | コマンド成功。上記未確認項目により全体 DoD 未達。 |

## Definition of Done の照合

| 項目 | 判定 |
|---|---|
| Acceptance Criteria を満たす | 未達: 可変幅・支援機能の実操作が残る。 |
| スコープ外変更なし | 確認: Task 4 は確認テスト・観測した本文入力不具合の局所修正・文書の追加。 |
| 関連 Apple 公式資料 / HIG 確認 | 確認: 上記3資料。 |
| 公式情報と独自判断を区別 | 確認: 本ログで分離。 |
| 可変幅で主要 UI 確認 | 未確認。 |
| Dark Mode に重大な問題なし | 確認した範囲は問題なし: 最大文字サイズとの組み合わせで入力・ペースト・Project編集のテストとNote編集画面の画像を確認。全フローの目視は未実施。 |
| Dynamic Type | 確認した範囲は問題なし: 空状態・Project編集・連続本文入力・ペースト・Note編集画面。 |
| VoiceOver の主要要素 | 未確認。 |
| 色だけへ依存しない | ソース確認、文章・trait を使用。 |
| Keyboard 操作 | 部分確認: Project 作成ショートカットのみ。 |
| Build / Lint 成功 | 確認。 |
| 新規コンパイラ警告なし | 確認: 既知 App Intents 警告のみ。 |
| 不要な抽象化なし | 確認。 |
| エラー処理考慮 | 確認: 無効タイトルと無効 ID をモデルで扱う。外部通信なし。 |
| 追加変更テスト成功 | 最大 Dynamic Type の失敗を修正し、反復3回と通常アプリ3テスト成功。標準環境の最終全実行7 + 9件も成功。 |
| 重要正常系 / 異常系 | 自動確認: 作成・編集・削除・選択、空白・欠落 ID。 |
| 必要 ADR 更新 | ADR-0004 Accepted を維持。新規判断なし。 |
| 要求と不一致なし | 要求変更なし。検証未達を明示。 |
| 学習ログ更新 | 本ファイル。 |

## 理解しづらかった点と次の Phase

NavigationSplitView の列表示、選択、端末幅は別の状態であり、広い画面でも sidebar が重なる場合がある。画像と AX で得られる情報も異なるため、自動テスト成功だけで可変幅や支援機能を確認したことにはならない。

まず残っている実操作の QA を済ませる。Phase 2 では SwiftData、再起動後の保持、保存操作、Note 単体削除を承認済み要求に沿って扱う。Phase 1 のメモリ上の即時反映と永続化を混同しない。
