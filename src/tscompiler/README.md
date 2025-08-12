# TypeScript Compiler Components

TypeScriptコンパイラの一部機能をMoonBitで実装した実験的プロジェクト。

## 概要

TypeScriptのコンパイルプロセスの理解を深めるため、主要コンポーネントをMoonBitで再実装。

## 実装済みコンポーネント

### Lexer/Tokenizer
- TypeScript構文のトークン化
- キーワード、識別子、リテラル、演算子の認識
- コメント、空白文字の処理

### Parser
- 式パーサー
- 文パーサー
- 宣言パーサー
- 優先順位と結合性の処理

### Type Checker（部分的）
- 基本型のチェック
- 型推論（簡易版）
- 型の互換性チェック

### AST Transformer
- AST変換パイプライン
- デコレータの展開（未実装）
- 構文糖衣の展開

## アーキテクチャ

```
Source Code
    ↓
Tokenizer → Token Stream
    ↓
Parser → AST
    ↓
Type Checker → Typed AST
    ↓
Transformer → Transformed AST
    ↓
Code Generator → JavaScript
```

## 実装例

### トークナイズ

```moonbit
let tokenizer = Tokenizer::new("const x: number = 42;")
let tokens = tokenizer.tokenize()
// [Const, Identifier("x"), Colon, Identifier("number"), Equals, Number(42), Semicolon]
```

### パース

```moonbit
let parser = Parser::new(tokens)
let ast = parser.parse_statement()
// VariableDeclaration {
//   kind: Const,
//   identifier: "x",
//   type_annotation: Some(NumberType),
//   initializer: Some(NumericLiteral(42))
// }
```

### 型チェック

```moonbit
let checker = TypeChecker::new()
let typed_ast = checker.check(ast)
// 型情報が付与されたAST
```

## サポートする構文（部分的）

- 変数宣言（const、let、var）
- 基本型（number、string、boolean）
- 関数宣言
- 式（算術、論理、比較）
- 制御構造（if、for、while）
- オブジェクト/配列リテラル

## 未実装機能

- クラス
- モジュールシステム
- ジェネリクスの完全サポート
- デコレータ
- 非同期関数
- JSX

## テスト

```bash
moon test src/tscompiler
```

## 学習リソース

このプロジェクトは以下を参考に実装:
- TypeScript Compiler API
- TypeScript AST Viewer
- TypeScript Deep Dive

## 注意

これは学習目的の実装であり、実用的なTypeScriptコンパイラではありません。