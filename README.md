# MoonBit Playground (2025-08)

MoonBit言語の学習と実験のためのリポジトリです。各種言語機能の探索と、TypeScript/Pythonとの相互運用を目的とした多言語コード生成システムを実装しています。

## 📦 パッケージ構成

### [src/jsonschema/](src/jsonschema/)
JSON Schemaの実装とバリデータ。MoonBitでJSON Schemaのバリデーションとコード生成を実現。

### [src/lambdaschema/](src/lambdaschema/)
TypeScriptの型システムを基準とした多言語コード生成システム。UniversalType中間表現を用いて、TypeScript、MoonBit、Python間の型定義を相互変換。

### [src/misc/](src/misc/)
MoonBit言語機能の学習用コード。基本構文、型システム、パターンマッチングなどの実験。

### [src/runtime/](src/runtime/)
ランタイムユーティリティとブリッジ実装。JavaScript/Node.js環境との相互運用層。

### [src/tscompiler/](src/tscompiler/)
TypeScriptパーサーとAST解析。TypeScript構文の解析とAST変換の実装。

### [src/typescript_parser/](src/typescript_parser/)
TypeScript型定義パーサー。`.d.ts`ファイルの解析と型情報の抽出。

## 🚀 主な機能

### 多言語コード生成 (`src/lambdaschema/`)
- **UniversalType**: 言語非依存の型表現
- **コード生成器**: TypeScript、MoonBit、Python+Pyrightに対応
- **相互運用性**: ジェネリクス、Union型、Promise/Result型の適切なマッピング

### JSON Schema実装 (`src/jsonschema/`)
- JSON Schemaバリデータ
- MoonBit型定義からJSON Schemaを生成
- Denoとの統合テスト

## 🧪 テスト

```bash
# MoonBitテストの実行
moon test --target all

# インテグレーションテスト（Deno）
cd tests && deno test

# 型チェック（生成されたTypeScriptコード）
deno check tests/tmp/generated_types.ts
```

## 📝 ライセンス

MIT

## 🔗 関連リンク

- [MoonBit公式サイト](https://www.moonbitlang.com/)
- [MoonBitドキュメント](https://www.moonbitlang.com/docs/)