# TypeScript Parser

TypeScript型定義（`.d.ts`）とソースコードのパーサー実装。

## 機能

- **型定義パース**: `.d.ts`ファイルの解析
- **AST生成**: TypeScript ASTの構築と操作
- **型情報抽出**: インターフェース、型エイリアス、関数シグネチャの抽出
- **Ambient Module**: `declare module`構文のサポート

## 主要コンポーネント

### パーサー (`parser.mbt`)
- トークナイザー: TypeScript構文のトークン化
- 型パース: 基本型、ジェネリック型、Union/Intersection型
- 宣言パース: interface、type alias、function、variable

### AST (`ast.mbt`)
TypeScript ASTノードの定義:
- Type: 型表現のASTノード
- Declaration: 宣言文のASTノード  
- Expression: 式のASTノード
- Statement: 文のASTノード

### 型システム (`types.mbt`)
- TypeReference: 型参照の解決
- Generic: ジェネリック型パラメータ
- TypeConstraint: 型制約（extends、implements）

## サポート構文

### 型定義
```typescript
// インターフェース
interface User {
  id: string;
  name: string;
  age?: number;
}

// 型エイリアス
type ID = string | number;
type Result<T> = { ok: T } | { err: Error };

// ジェネリック関数
function map<T, U>(arr: T[], fn: (x: T) => U): U[];

// Ambient Module
declare module "my-module" {
  export function myFunc(): void;
}
```

### 高度な型
- Union型: `A | B`
- Intersection型: `A & B`  
- Conditional型: `T extends U ? X : Y`
- Mapped型: `{ [K in keyof T]: T[K] }`
- Template Literal型: `` `prefix_${T}` ``

## 使用例

```moonbit
let source = """
interface Point {
  x: number;
  y: number;
}

function distance(p1: Point, p2: Point): number {
  return Math.sqrt((p2.x - p1.x) ** 2 + (p2.y - p1.y) ** 2);
}
"""

let parser = Parser::new(source)
let ast = parser.parse()
```

## テスト

```bash
moon test src/typescript_parser
```

## 制限事項

- デコレータは未サポート
- JSX構文は未サポート
- 一部の最新TypeScript機能は未実装