# Networking実装スキル

## 原則

Foundation / URLSession / Swift Concurrencyを第一候補とする。

## 実装チェック

- URLRequestの生成責務
- HTTP status validation
- Codable decode
- Cancellation
- Timeout
- Error mapping
- Retryが本当に必要か
- API DTOとSwiftDataモデルの境界
- MainActorの範囲
- APIキーの保護

## テスト

実Web APIへ常時アクセスするテストを標準にしない。

HTTP境界を制御可能にし、成功・HTTPエラー・不正レスポンス・通信失敗・キャンセルを検証する。
