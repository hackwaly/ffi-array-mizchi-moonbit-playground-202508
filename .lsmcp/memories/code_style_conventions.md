---
created: 2025-08-10T07:45:37.292Z
updated: 2025-08-10T07:45:37.292Z
---

# MoonBit コードスタイルと規約

## 命名規約
- **関数名**: snake_case (例: `hello()`)
- **パッケージ名**: lowercase (例: `lib`, `main`)
- **モジュール名**: username/projectname 形式 (例: `username/hello`)

## ファイル構造
- **.mbt**: MoonBit ソースファイル
- **_test.mbt**: テストファイル（例: `hello_test.mbt`）
- **moon.pkg.json**: パッケージ設定ファイル
- **moon.mod.json**: モジュール設定ファイル

## テスト規約
```moonbit
test "test_name" {
  if condition {
    fail("error message")
  }
}
```

## インポート規約
- 他のパッケージは `@` プレフィックスで参照（例: `@lib.hello()`）
- moon.pkg.jsonの`import`フィールドで依存関係を宣言

## 関数定義
```moonbit
pub fn function_name() -> ReturnType {
  // 実装
}
```

## メインエントリーポイント
```moonbit
///|
fn main {
  // メイン処理
}
```
- `///|` コメントはメイン関数の前に配置
- moon.pkg.jsonで `"is-main": true` を設定

## ディレクトリ構造
- `src/`: ソースコードのルートディレクトリ
- `src/lib/`: ライブラリパッケージ
- `src/main/`: メインパッケージ（実行可能）
- `target/`: ビルド成果物（gitignore対象）