# Definition of Done

機能は以下を満たして初めてDoneとする。

Simulator の手動操作が必要な Apple Platform / Accessibility の確認は人間が行う。自動テストは Swift Testing と XCTest のみを対象とし、XCTest UI Test の自動実行は含む。人間の確認結果と自動テスト結果を区別して記録し、未確認項目を完了扱いにしない。

## 要求

- [ ] Acceptance Criteriaを満たしている。
- [ ] スコープ外の変更を混入していない。

## Apple Platform

- [ ] 関連するApple公式ドキュメント/HIGを確認した。
- [ ] 公式情報と独自判断を区別している。
- [ ] iPadの可変ウインドウ幅で主要UIを確認した。
- [ ] Dark Modeで重大な問題がない。

## Accessibility

- [ ] Dynamic Typeを確認した。
- [ ] VoiceOverで主要要素の意味が分かる。
- [ ] 色だけに意味を依存していない。
- [ ] 対象Phaseで要求されるKeyboard操作を確認した。

## Code

- [ ] Build成功。
- [ ] `scripts/lint.sh` が成功する。
- [ ] 新規コンパイラ警告なし。
- [ ] 不要な抽象化を追加していない。
- [ ] エラー処理を考慮した。

## Test

- [ ] 追加・変更したテストが成功する。
- [ ] 重要な正常系を検証している。
- [ ] 重要な異常系を検証している。

## Documentation

- [ ] 必要なADRを更新した。
- [ ] 要求との不一致がない。
- [ ] 学習ログを更新した。
