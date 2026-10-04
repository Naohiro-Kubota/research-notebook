# AI駆動開発プロセス

## 基本サイクル

```text
要求（Human）
  ↓
調査（AI）
  ↓
設計候補・トレードオフ（AI）
  ↓
重要判断（Human）
  ↓
ADR更新（AI → Human承認）
  ↓
実装（AI）
  ↓
テスト（AI）
  ↓
HIG / Accessibilityレビュー（AI）
  ↓
成果レビュー（Human）
```

## 1機能の開始条件

- 要求が説明できる。
- Acceptance Criteriaがある。
- 未決定の重要判断が識別されている。

## 作業環境

作業ごとに`origin/develop`の最新状態を取得し、それを起点に専用の作業ブランチを作成する。そのブランチをチェックアウトしたGit Worktreeを作成し、ファイル変更、ビルド、テストはそのWorktree内で行う。共有の作業ディレクトリや基点ブランチを直接変更しない。

Xcode の Build / Test では、作業中の Worktree 内の `DerivedData/` を `-derivedDataPath` に指定する。Codex の設定に個別の Worktree の絶対パスを追加しない。

端末固有の Codex 権限は、Git 管理対象の `.codex/config.toml` ではなく、各開発者の `~/.codex/config.toml` に設定する。次は、このリポジトリを `~/Project/ai/research-notebook` に置く場合の例。配置先が異なる場合は `.git` のパスを変更する。

```toml
default_permissions = "research-notebook-git"
approval_policy = "on-request"

[permissions.research-notebook-git]
extends = ":workspace"

[permissions.research-notebook-git.filesystem]
"~/Project/ai/research-notebook/.git" = "write"
"~/.codex/worktrees" = "write"
"~/Library/Developer/Xcode/DerivedData" = "write"
"~/Library/Developer/CoreSimulator" = "write"
"~/Library/Developer/Xcode" = "write"
```

既存の `~/.codex/config.toml` がある場合は、同名のキーやテーブルを確認して統合する。`sandbox_mode` や `[sandbox_workspace_write]` は permission profile と併用せず、残っていれば削除する。上記の `~/.codex/worktrees` はこのリポジトリ以外の管理 Worktree にも書き込みを許可するため、必要性に応じて各自が設定する。Xcode 関連ディレクトリも、利用する開発環境に応じて選ぶ。権限の仕組みとパス記法は 2026-10-04 に [OpenAI 公式 Permissions 資料](https://learn.chatgpt.com/docs/permissions)で確認した。

スクリプトを一律に sandbox 外で許可しない。Worktree 内のスクリプトは編集できるため、一律許可するとリスト外への書き込みも承認を経ずに実行できる。iPad Simulator を使う `scripts/test.sh` は現在の sandbox 内で CoreSimulatorService に接続できず、sandbox 外での実行が必要になる。この制限は Worktree の書き込み権限だけでは解消しない。

作業完了時は作業ブランチをpushし、GitHubの`develop`ブランチをbaseとするPull Requestを作成する。PRのタイトルと本文は日本語で記述する。

GitHub Actions の Build / Test は Pull Request の作成・更新時に実行する。ブランチへの push だけでは実行しない。

このプロジェクトでは `.codex/rules/github.rules` により、`gh pr` と `gh api` のサンドボックス外実行を承認なしで許可する。PR の編集や任意の GitHub API 操作もこの許可に含まれる。

`.codex/rules/xcode-testing.rules` により、`xcodebuild` と `xcrun xcresulttool` から始まるコマンドのサンドボックス外実行を承認なしで許可する。両方の許可は後続の引数やサブコマンド全体に適用される。2026-10-04 に [OpenAI 公式 Rules 資料](https://learn.chatgpt.com/docs/agent-configuration/rules)で構文と適用条件を確認した。プロジェクトの `.codex/` 設定が信頼されている場合にルールが読み込まれ、追加後は Codex の再起動が必要。

## AIの調査出力

Apple固有事項では、実装前に必要に応じて以下を提示する。

- 調査対象
- Apple公式情報
- 確認日
- 分かったこと
- 選択肢
- 推奨案と理由
- 人間に判断してほしい事項

## 実装

小さな単位で変更する。

実装中に要求・ADRと矛盾する必要が生じた場合、勝手に迂回せず作業を止めて判断を求める。

## レビュー

レビューではコードだけでなく以下を見る。

- 要求適合
- Apple APIの適切な利用
- データフロー
- 不要な抽象化
- エラー・キャンセル
- Accessibility
- テスト
- ドキュメント

## 学習ログ

各Phase終了時、`docs/learning/` に次を記録する。

- 新しく学んだiPadOS / Swift概念
- AIの提案で理解しづらかった箇所
- 人間が覆したAIの判断
- 次Phaseで深掘りしたい事項
