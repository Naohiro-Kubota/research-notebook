# ADR-0001: SwiftUIネイティブなデータフローを初期方針とする

- Status: Proposed
- Date: 2026-09-29
- Decision Owner: Human

## Context

Research Notebookの初期アーキテクチャを決める必要がある。SwiftUI開発経験がないため、特定パターンを慣習だけで導入せず、Appleの現在の設計思想を学習できる構成を採用したい。

## Apple公式情報・一次情報

- WWDC26 SwiftUI Group Lab: SwiftUIチームは特定のMVC/MVVM/VIPER/Clean Architecture等の採用を期待しておらず、SwiftUIはarchitecture-agnosticと説明している。
- SwiftUI / Observation / SwiftDataの公式ドキュメントを各実装Phaseで追加調査する。

## Decision Drivers

- Apple標準技術を学習できること。
- 不要な抽象化を避けること。
- テスト可能性を損なわないこと。
- 機能拡張時に構造を進化させられること。

## Options

### A. SwiftUIネイティブなデータフローから開始

必要になるまでViewModel / Repository / UseCase等を一律には導入しない。

### B. MVVMを全画面へ適用

すべてのViewにViewModelを配置する。

### C. Clean Architectureを初期から適用

Presentation / UseCase / Domain / Repository等を初期から分離する。

## Proposed Decision

Option Aを提案する。

これは「MVVMを禁止する」という判断ではない。具体的な問題を解決するためにViewModel等が必要になれば、その時点で導入する。

## Human Decision

未承認。
