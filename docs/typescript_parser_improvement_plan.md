# TypeScript Parser 改善計画書

## 概要

本文書は、ベースライン結果（2025-08-10 19:13:14 JST）を基に、typescript_parser の不具合/未対応機能を分析し、最短でグリーンに近づけるための改善方針・設計・優先度付きバックログを策定したものです。

## 現状サマリー（ベースライン抜粋）

### テスト結果

- **MoonBit**: 総数 123, 成功 121, 失敗 2
- **Deno**: 総数 1, 成功 1, 失敗 0（ただし JS ビルドエラー 12 件）

### 失敗詳細

1. **タプル型パース失敗** (`src/typesrcipt_parser/new_features_test.mbt:37`)

   - テスト名: `parse tuple type`
   - エラー: `expect test failed - Diff: first is numbertrue`
   - 入力: `type Point = [number, number]`

2. **リテラル型 Union 判定失敗** (`src/typesrcipt_parser/new_features_test.mbt:71`)
   - テスト名: `parse literal types`
   - エラー: `expect test failed - Diff: should be unionfalse`
   - 入力: `type Status = "success" | "error" | "pending"`

## 失敗分類

### parser/types カテゴリ（2 件）

- **タプル型パース**: パーサーロジックの不具合
- **リテラル型 + Union**: 型判定ロジックの不具合

### tooling/js_build カテゴリ（12 件）

- **JS ビルドエラー**: CommonJS/ESM 互換性問題
- **優先度**: 低（パーサー精度の直接要因ではないため別トラック扱い）

## 根本原因分析

### タプル型パース失敗

**問題箇所**: `src/typesrcipt_parser/parser.mbt:144`

```moonbit
match self.parse_type() {
  Some(typ) => {
    types.push(typ)
    self.next_token() // ← この呼び出しが不適切
  }
  None => return None
}
```

**原因**: 型パース後の不適切な `next_token()` 呼び出しにより、後続処理でトークン位置がずれる

**修正方針**: `parse_type()` 呼び出し後の `next_token()` を削除し、適切なトークン管理を実装

### リテラル型 + Union パース失敗

**問題箇所**: `src/typesrcipt_parser/parser.mbt:111`

```moonbit
// ユニオン型: T | U | ...
if self.peek_token_is(Token::Pipe) {
  // ← この時点でトークン位置が不正
```

**原因**: リテラル型パース後、Union 判定時のトークン位置管理が不適切

**修正方針**: リテラル型パース後のトークン位置を正しく管理し、Union 判定を適切に実行

## 設計詳細

### 文法定義と優先順位

```
Type := UnionType
UnionType := IntersectionType ("|" IntersectionType)*
IntersectionType := PrimaryType ("&" PrimaryType)*
PrimaryType := TupleType | LiteralType | TypeReference | ParenthesizedType

TupleType := "[" Type ("," Type)* (",")? "]"
LiteralType := StringLiteral | NumberLiteral | BooleanLiteral | NullLiteral
```

**優先順位（高 → 低）**:

1. `PrimaryType` (Tuple, Literal, TypeRef, Parenthesized)
2. `IntersectionType` (`&`)
3. `UnionType` (`|`)

**結合規則**: 左結合（`A | B | C` = `(A | B) | C`）

### エラーポリシー

- **空タプル** `[]`: エラーとして扱う（TypeScript 仕様準拠）
- **不正な末尾カンマ**: 許容する（`[number, string,]`）
- **ネスト制限**: 実装上の制限なし

## 追加テスト一覧

### タプル型テストケース（6 ケース）

1. **基本タプル**: `[number]` → `Tuple([Number])`
2. **複数要素**: `[number, string, boolean]` → `Tuple([Number, String, Boolean])`
3. **ネストタプル**: `[number, [string, boolean]]` → `Tuple([Number, Tuple([String, Boolean])])`
4. **末尾カンマ**: `[number, string,]` → `Tuple([Number, String])`
5. **Union 内タプル**: `[number, (string | boolean)]` → `Tuple([Number, Union([String, Boolean])])`
6. **空タプル**: `[]` → エラー

### リテラル型テストケース（6 ケース）

1. **文字列リテラル**: `"success"` → `Literal(String("success"))`
2. **数値リテラル**: `42` → `Literal(Number("42"))`
3. **真偽値リテラル**: `true` → `Literal(Boolean(true))`
4. **文字列 Union**: `"a" | "b" | "c"` → `Union([Literal(String("a")), ...])`
5. **数値 Union**: `1 | 2 | 3` → `Union([Literal(Number("1")), ...])`
6. **混合 Union**: `"error" | 404 | false` → `Union([Literal(String("error")), Literal(Number("404")), Literal(Boolean(false))])`

### 回帰テストケース（2 ケース）

1. **import type**: `import type { User } from "./types"` → 既存動作維持
2. **export type**: `export type Status = string` → 既存動作維持

## 優先度付きバックログ

### P0: 既存失敗の修正（必須・即座対応）

1. **タプル型パース修正**

   - 関数: `parse_tuple_type()` (parser.mbt:132)
   - 変更: 144 行目の `self.next_token()` 削除
   - 期待: `parse tuple type` テストのグリーン化

2. **リテラル型 Union 判定修正**

   - 関数: `parse_type()` (parser.mbt:111)
   - 変更: Union 判定時のトークン位置管理改善
   - 期待: `parse literal types` テストのグリーン化

3. **既存失敗 2 件のグリーン化確認**
   - 対象: `parse tuple type`, `parse literal types`
   - 検証: テスト実行結果の確認

### P1: タプル型機能拡張（重要・短期）

4. **末尾カンマ対応**

   - 機能: `[number, string,]` の許容
   - 実装: `parse_tuple_type()` の条件分岐追加

5. **ネストタプル対応**

   - 機能: `[number, [string, boolean]]` のパース
   - 実装: 再帰的な `parse_type()` 呼び出し確認

6. **空タプル仕様策定**
   - 機能: `[]` のエラーハンドリング
   - 実装: 適切なエラーメッセージ返却

### P2: リテラル型機能拡張（重要・中期）

7. **真偽値リテラル対応**

   - AST 拡張: `LiteralType::Boolean(Bool)` の活用
   - Lexer 確認: `true`, `false` キーワードトークン
   - Parser 実装: `parse_type()` での真偽値判定追加

8. **null リテラル対応**

   - AST 確認: `Type::Null` の活用
   - Parser 実装: `null` キーワードのリテラル型扱い

9. **混合 Union 対応**
   - 機能: `"error" | 404 | false` の複合型
   - 実装: Union 内での異種リテラル型の組み合わせ

### P3: 回帰防止・周辺対応（通常・長期）

10. **import/export type 回帰テスト**

    - 対象: 既存の import/export 機能
    - 検証: 型パース変更による影響確認

11. **JS ビルドエラー対応**

    - 分類: tooling/js_build（別トラック）
    - 内容: CommonJS/ESM 互換性問題
    - 優先度: 低（パーサー精度とは独立）

12. **パフォーマンス最適化**
    - 対象: パーサー全体の効率化
    - 手法: 不要なトークン読み込み削減

## 影響範囲・段階導入

### 変更対象ファイル

- **lexer.mbt**: 変更不要（既存トークンで対応可能）
- **parser.mbt**: 主要変更対象
  - `parse_tuple_type()`: トークン管理修正
  - `parse_type()`: Union 判定ロジック修正
  - `parsePrimaryType()`: リテラル型判定追加（必要に応じて）
- **ast.mbt**: 最小限の変更
  - 既存の `Tuple`, `Literal`, `Union` 型を活用
  - 新規ノード追加は不要
- **codegen.mbt**: 今回は対象外（パース精度が主眼）

### API 互換性

- **外部公開 API**: 破壊的変更なし
- **内部実装**: `parse_type()` の動作改善のみ
- **AST 構造**: 既存構造を維持

## ロールアウト手順

### 1. 実装フェーズ

1. **P0 実装**: 既存失敗 2 件の修正
2. **P0 検証**: `moon test src/typesrcipt_parser/` での確認
3. **P1 実装**: タプル型機能拡張
4. **P1 検証**: 追加テストケースでの確認
5. **P2 実装**: リテラル型機能拡張（必要に応じて）

### 2. パッケージ内テスト

- **対象**: `src/typesrcipt_parser/` 内の全テスト
- **コマンド**: `moon test src/typesrcipt_parser/`
- **期待**: 既存テスト + 新規テストの全パス

### 3. ルート全体テスト

- **対象**: プロジェクト全体
- **コマンド**: `moon test`
- **期待**: 失敗数 2 → 0 への改善

### 4. レポート更新

- **ベースライン再測定**: 改善後の結果記録
- **成果確認**: MoonBit 123/123 パス達成

## 次に着手すべき P0 実装タスク

**最優先タスク**: `parse_tuple_type()` 関数の修正

- **ファイル**: `src/typesrcipt_parser/parser.mbt`
- **行番号**: 144 行目
- **変更内容**: `self.next_token()` 呼び出しの削除
- **検証方法**: `parse tuple type` テストの実行確認

---

_作成日: 2025-08-10_  
_対象ベースライン: baseline-20250810-1856_
