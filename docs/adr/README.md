# ADR運用

Architecture Decision Recordは、重要な設計判断とその理由を将来の人間・AIへ伝えるために使用する。

## 状態

- Proposed: AIまたは人間が提案中
- Accepted: 人間が承認済み
- Superseded: 後続ADRで置き換え済み
- Rejected: 採用しなかった

## 命名

`NNNN-短いタイトル.md`

例：`0004-web-api-selection.md`

## 手順

1. AIが公式情報を調査する。
2. Contextと選択肢を整理する。
3. メリット・デメリットを提示する。
4. AIは推奨案を提示してよいが、重要判断をAcceptedにしない。
5. 人間が判断する。
6. 承認後にStatusをAcceptedへ変更する。
