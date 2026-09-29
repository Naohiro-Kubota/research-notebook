# Codex作業開始プロンプト集

## Phase開始

```text
AGENTS.mdと関連ドキュメントを読んでください。
今回は docs/learning/roadmap.md の Phase N を進めます。

まだ実装を開始しないでください。
まず以下を提示してください。
1. このPhaseの要求とAcceptance Criteria案
2. 学習対象となるSwift/iPadOS概念
3. 調査が必要なApple公式情報
4. 重要な設計判断とADR要否
5. 小さく分割した実装計画
6. 人間による承認が必要な事項

Appleプラットフォーム固有事項についてはApple公式一次情報を優先してください。
```

## 実装開始

```text
承認済みの要求・ADR・実装計画に従って次の作業単位を実装してください。

実装後に以下を実施してください。
- Build
- Test
- 関連ドキュメント更新
- Definition of Doneの確認

要求またはADRと矛盾する必要が生じた場合は、勝手に変更せず作業を止めて報告してください。
```

## レビュー

```text
今回の変更をレビューしてください。

特に以下を確認してください。
- 要求適合
- Apple公式API/HIGとの整合
- SwiftUIのデータフロー
- 不要なViewModel/Repository/Protocol等の抽象化
- async/awaitとキャンセル
- エラーハンドリング
- Accessibility
- テスト不足
- ADR/ドキュメント不足

重大度と根拠を付けて指摘してください。問題がない項目を無理に指摘しないでください。
```
