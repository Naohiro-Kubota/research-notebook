# ADR-0004: Notebook の 3 列 Navigation 構造

- Status: Accepted
- Date: 2026-10-04
- Decision Owner: Human

## Context

Phase 1 は Project 一覧、選択した Project の Note 一覧、Note 編集を提供する。iPad の可変ウインドウ幅で階層を移動でき、どの Project と Note を編集中か分かる必要がある。Deployment Target は iPadOS 17。

## Apple 公式情報・一次情報

| 資料 | URL | 確認日 | 公式資料から分かった事実 |
|---|---|---|---|
| NavigationSplitView | https://developer.apple.com/documentation/swiftui/navigationsplitview | 2026-10-04 | 2 列または 3 列を構成でき、先行列の選択が後続列に反映される。狭い環境では列がスタックに折りたたまれる。 |
| TN3154: Adopting SwiftUI navigation split view | https://developer.apple.com/documentation/technotes/tn3154-adopting-swiftui-navigation-split-view | 2026-10-04 | NavigationSplitView は iOS 16 以降で利用できる。 |
| Human Interface Guidelines — Split views | https://developer.apple.com/design/human-interface-guidelines/split-views | 2026-10-04 | iPadOS では 2 列と 3 列の分割ビューがあり、狭い・中間・広いウインドウ幅を考慮する。選択した階層を視覚的に示すことを勧める。 |
| SwiftUI on iPad: Organize your interface (WWDC22) | https://developer.apple.com/videos/play/wwdc2022/10058/ | 2026-10-04 | 3 列の表示列は幅や向きで変わり、コンパクトな環境ではスタックになる。 |

## Decision Drivers

- Project → Note → 編集の階層を分かりやすくする。
- iPad の広さを活用しつつ、狭いウインドウでも移動できる。
- SwiftUI の標準 Navigation API を使い、独自の列管理を最小化する。
- Phase 1 の学習対象である NavigationSplitView を実際の操作で検証できる。

## Options

### A. 3 列の NavigationSplitView

Project 一覧を sidebar、Note 一覧を content、Note 編集を detail に置く。

**利点:** 階層と選択の関係を列で表し、広い画面では一覧と編集を同時に参照できる。SwiftUI 標準の幅への適応を利用できる。

**欠点・リスク:** 常に 3 列が並ぶわけではない。狭い幅での戻り方、空状態、削除後の選択解除、本文の編集領域は実画面で確認が必要。

### B. 2 列の NavigationSplitView と Note 一覧からの遷移

Project 一覧を sidebar に置き、detail 側で Note 一覧と編集を切り替える。

**利点:** 編集領域を広く取りやすい。列間の選択関係が一段少ない。

**欠点・リスク:** 広い画面でも Note 一覧と編集を並べて参照する構成には追加の Navigation が必要。3 階層の現在位置を把握しにくくなる可能性がある（AI の推測）。

## Proposed Decision

AI は A を提案する。Project／Note の選択をそれぞれ保持し、Project の切替・削除時に無効な Note 選択を解除する。最初は標準の列表示に任せ、幅や折りたたみで具体的な問題が確認された場合にだけ列表示の制御を追加する。

## Human Decision

2026-10-04、人間は 3 列案を Phase 1 の Navigation 構造として承認した。同日、本 ADR を最終承認した。

## Consequences and Verification

- Project 一覧、Note 一覧、Note 編集の空状態と選択解除を設計・テストする。
- iPad の全画面、狭いウインドウ、可能なら中間幅で Project → Note → 編集と戻る操作を確認する。
- Dynamic Type、VoiceOver、キーボード操作で列をまたぐ主要フローを確認する。
- 公式資料に基づく妥当性は確認済みだが、実アプリのレイアウトと操作性は未検証。実装後の確認結果を学習ログに記録する。
