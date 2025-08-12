# Lambda Schema - Multi-Language Code Generation

TypeScriptの型システムを基準とした多言語コード生成システム。UniversalType中間表現を用いて、TypeScript、MoonBit、Python間で型定義を相互変換します。

## 🎯 目的

ジェネリクスを持つ異なる言語間で一貫した型定義を生成し、相互運用可能なコードを作成する。

## 🏗️ アーキテクチャ

```
TypeScript AST → UniversalType → { TypeScript, MoonBit, Python }
```

## 主要コンポーネント

### UniversalType (`universal_types.mbt`)
言語非依存の型表現。すべての言語に共通する型概念を抽象化。

- 基本型: String, Number, Boolean, etc.
- 複合型: Array, Tuple, Object, Union, Intersection
- ジェネリック: TypeParameter, TypeApplication
- 特殊型: Promise, Result, Option

### コード生成器

#### TypeScript (`codegen_typescript.mbt`)
- 完全なTypeScript型システムサポート
- Union/Intersection型
- Conditional型
- async/await

#### MoonBit (`codegen_moonbit.mbt`)
- MoonBit固有の型システムへのマッピング
- Union → enum変換
- Promise → Result[T, Error]変換
- Option型のネイティブサポート

#### Python+Pyright (`codegen_python.mbt`)
- 型ヒント完全対応
- TypedDict, Protocol
- Generic, TypeVar
- Literal型

## 型マッピング表

| UniversalType | TypeScript | MoonBit | Python |
|---|---|---|---|
| String | string | String | str |
| Number | number | Double | float |
| Integer | number | Int | int |
| Boolean | boolean | Bool | bool |
| Array(T) | T[] | Array[T] | List[T] |
| Optional(T) | T \| undefined | T? | Optional[T] |
| Promise(T) | Promise<T> | Result[T, Error] | Awaitable[T] |
| Union([T1, T2]) | T1 \| T2 | enum { T1, T2 } | T1 \| T2 |
| Function | (...) => R | fn(...) -> R | Callable[..., R] |

## 使用例

```moonbit
// 型定義
let user_type = UniversalType::Object(Map::from([
  ("id", ObjectField::{ field_type: String, optional: false, readonly: true }),
  ("name", ObjectField::{ field_type: String, optional: false, readonly: false }),
  ("age", ObjectField::{ field_type: Integer, optional: true, readonly: false })
]))

// コード生成
let ts_code = generate_typescript(user_type)
let mb_code = generate_moonbit(user_type)
let py_code = generate_python(user_type)
```

## インテグレーションテスト

生成されたコードの相互運用性を検証:

```bash
# TypeScript型チェック
deno check tests/tmp/generated_types.ts

# Pythonテスト
python3 tests/tmp/generated_types.py

# 相互運用テスト
deno run tests/tmp/test_interop.ts
```

## アーカイブ (`archive/`)

実験的な機能や未完成の実装:
- 高階型（Higher-Kinded Types）
- Effect型システム
- 型推論エンジン
- RPCスキーマ生成