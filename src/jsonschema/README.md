# JSON Schema Implementation

MoonBitによるJSON Schema実装とバリデータ。

## 機能

- **JSON Schemaバリデーション**: Draft-07準拠のバリデーション実装
- **型定義生成**: JSON SchemaからMoonBit型定義を生成
- **スキーマ構築DSL**: 直感的なDSLでJSON Schemaを構築

## 主要コンポーネント

### バリデータ (`validator.mbt`)
- 基本型バリデーション（string, number, boolean, null）
- 配列/オブジェクトバリデーション
- パターンマッチング、長さ制限、範囲チェック
- 必須フィールド、追加プロパティの制御

### コード生成 (`codegen.mbt`)
- JSON SchemaからMoonBit構造体を生成
- 型マッピング（string → String, number → Double, etc.）
- オプショナルフィールドのサポート

### スキーマビルダー (`builder.mbt`)
- チェーンメソッドでスキーマを構築
- 型安全なAPI設計

## 使用例

```moonbit
// スキーマ定義
let user_schema = object_schema()
  .property("id", string_schema().min_length(1))
  .property("name", string_schema())
  .property("age", number_schema().minimum(0.0).maximum(150.0))
  .required(["id", "name"])
  .build()

// バリデーション
let valid = validate(user_json, user_schema)
```

## テスト

```bash
moon test src/jsonschema
```

Denoとの統合テスト:
```bash
cd tests && deno test deno_integration_test.ts
```