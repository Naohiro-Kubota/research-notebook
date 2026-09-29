# Research Notebook プロダクト要求

## 1. プロダクトビジョン

Research Notebookは、調査中に得たメモ、Webリソース、文書、画像などをプロジェクト単位で整理し、iPad上で継続的に参照・編集できるアプリである。

本プロジェクトには「有用なアプリを作る」ことに加え、「AI駆動開発を通じてiPadOS開発を体系的に学習する」という目的がある。

## 2. 想定ユーザー

- 技術調査や学習を行う個人
- Web記事、論文、PDF、メモをまとめて管理したい人
- iPadを長時間の調査・整理作業に利用する人

## 3. コア概念

### Project
調査テーマをまとめる単位。

### Research Item
Project内で管理する調査情報。将来的にNote、Web Resource、Document、Imageなどを扱う。

### Tag
Research Itemを横断的に分類する情報。

## 4. 初期MVP

最初のMVPでは以下を実現する。

- Projectを作成・編集・削除できる。
- ProjectにNoteを作成・編集・削除できる。
- ProjectとNoteをローカルへ永続化できる。
- iPadの画面サイズ変化に対応できる。

## 5. 段階的に追加する機能

- タグ
- 検索
- Web APIを利用した外部情報検索
- Web Resource保存
- PDF / Files取り込み
- Drag & Drop
- Keyboard Shortcut
- Pointer対応
- Share
- Apple Pencilによる手書きメモ
- 複数ウインドウ
- 状態復元

## 6. Web API題材

外部の公開Web APIから研究対象を検索し、結果をResearch Itemとして保存する機能を追加する。

API自体は実装Phaseで候補を調査し、人間が承認する。候補例として文献・論文メタデータAPIなどを想定するが、本要求では特定サービスへ固定しない。

学習対象：

- HTTP
- URLSession
- async/await
- Codable
- エラーハンドリング
- キャンセル
- Loading / Empty / Error UI
- APIモデルと永続化モデルの境界
- Network Test

## 7. 非機能要求

### UX

Apple HIGを一次情報として設計する。

iPadの大画面、可変ウインドウ、複数入力方式を活用する。

### Accessibility

VoiceOver、Dynamic Type、キーボード操作などを段階的に検証する。

### 品質

- Build可能であること。
- 自動テストを維持すること。
- コンパイラ警告を原則として放置しないこと。
- 重要な設計判断をADRとして残すこと。

### セキュリティ・プライバシー

- 秘密情報をリポジトリへ保存しない。
- 外部通信やユーザーデータの扱いは実装前に確認する。
- 不要な権限を要求しない。

## 8. 対象外（初期）

- ユーザーアカウント
- 独自バックエンド
- 複数端末同期
- 課金
- App Store公開
- AI/LLM機能

これらは学習状況に応じて別途要求として追加する。
