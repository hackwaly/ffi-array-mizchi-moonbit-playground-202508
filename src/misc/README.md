# Miscellaneous - MoonBit学習コード

MoonBit言語の各種機能を学習・実験するためのコード集。

## 内容

### 基本構文 (`basic.mbt`)
- 変数宣言（let、mut）
- 基本型（Int、String、Bool、Double）
- 関数定義
- パターンマッチング

### 型システム (`types.mbt`)
- カスタム型定義（struct、enum）
- ジェネリクス
- 型エイリアス（typealias）
- トレイト（trait）

### コレクション (`collections.mbt`)
- Array操作
- Map/Set
- イテレータ

### エラーハンドリング (`error.mbt`)
- Result型
- Option型
- try/catch構文
- カスタムエラー型

### 非同期処理 (`async.mbt`)
- Promise相当の処理
- コールバックパターン
- FFIを使った非同期操作

### パフォーマンス (`perf.mbt`)
- ベンチマーク
- メモリ管理
- 最適化テクニック

## 学習メモ

### MoonBitの特徴
- **イミュータブルがデフォルト**: 変更可能にするには`mut`が必要
- **強力な型推論**: 多くの場合型注釈は不要
- **パターンマッチング**: 網羅性チェック付き
- **エラー処理**: Result/Option型による明示的なエラー処理
- **FFI**: JavaScript/WASMとの相互運用が容易

### よくあるパターン

```moonbit
// Option型の処理
match optional_value {
  Some(v) => process(v)
  None => default_value
}

// Result型のエラー処理
let result = risky_operation()?
// または
match risky_operation() {
  Ok(value) => use_value(value)
  Err(error) => handle_error(error)
}

// ジェネリック関数
fn identity[T](value : T) -> T {
  value
}
```

## 実行方法

個別のテストを実行:
```bash
moon test src/misc/basic.mbt
```

すべてのテストを実行:
```bash
moon test src/misc
```