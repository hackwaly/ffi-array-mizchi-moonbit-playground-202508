# mizchi/tskit

ES Module Runtime FFI Bindings for MoonBit - JavaScript 相互運用ライブラリ

## 概要

`esmbt`は、MoonBit から JavaScript ランタイムの機能にアクセスするための FFI（Foreign Function Interface）バインディングを提供するライブラリです。ES Modules 環境で動作し、Deno、Node.js、ブラウザなど複数のランタイムをサポートします。

## ディレクトリ構造

```
src/
├── runtime/
│   ├── types.mbt     # 型定義
│   ├── es.mbt        # ES Module FFIバインディング
│   └── moon.pkg.json
├── fetch/            # Fetch APIの実装例
├── lib/              # その他のライブラリ
└── main/             # メインエントリーポイント
```

## 機能

### Core APIs

- Console operations (log, error, warn, info, debug)
- Time functions (Date.now, performance.now)
- Timers (setTimeout, setInterval, clearTimeout, clearInterval)
- Runtime detection (Deno, Node.js, Browser, Worker)

### Promise Support

- Promise creation and manipulation
- Error handling

### Network

- Fetch API (when available)
- JSON parsing/serialization

### Event System

- Event emitter pattern support

## 使用方法

```moonbit
// ES Runtimeのインスタンスを作成
let runtime = @runtime.ESRuntime::new()

// コンソールログ
runtime.log("Hello from MoonBit!")

// ランタイム検出
let env = runtime.detect_runtime()
runtime.log("Running on: \{env}")

// タイマー
let _ = runtime.set_timeout(fn() {
  runtime.log("Timer fired!")
}, 1000)

// Fetch (利用可能な場合)
let response = runtime.fetch("https://api.example.com/data")
```

## ビルド

```bash
moon build --target js
```

## ツール

### mbt-init.ts

新しい MoonBit + JavaScript 相互運用プロジェクトを生成する CLI ツール

```bash
./mbt-init.ts my-project --runtime=es
```

### mbtrun.ts

MoonBit ファイルを直接実行する Deno ラッパー

```bash
./mbtrun.ts my-script.mbt
```

## ライセンス

MIT

## DTS parser subset for sample-bindings.ts

本リポジトリには、TypeScript の最小サブセットから Moonbit 向け FFI コードを生成する ts_parser 実装が含まれます。このサブセットは [sample-bindings.ts](sample-bindings.ts) をカバーし、実装は以下のパーサ/コード生成/テストに基づきます。

- パーサ中核: [Parser::parse_type()](src/ts_parser/parser.mbt:51), [Parser::parse_qualified_name()](src/ts_parser/parser.mbt:335), [Parser::parse_type_arguments()](src/ts_parser/parser.mbt:355), [Parser::parse_function_declaration()](src/ts_parser/parser.mbt:444), [Parser::parse_import_declaration()](src/ts_parser/parser.mbt:961)
- AST 型: [Type](src/ts_parser/ast.mbt)
- コード生成 API: [type_to_moonbit()](src/ts_parser/codegen.mbt:6), [generate_function_binding()](src/ts_parser/codegen.mbt:151), [generate_type_alias_binding()](src/ts_parser/codegen.mbt:272), [generate_ffi_code()](src/ts_parser/codegen.mbt:293)

### 1) 概要

- 本 ts_parser は TypeScript のサブセットを対象に、FFI 用の Moonbit コードを生成します。
- サブセットは [sample-bindings.ts](sample-bindings.ts) の記述をカバーします（型とシグネチャ情報に限定）。

### 2) 対応サブセット（構文仕様）

- Import（型名前空間）:
  - `import type * as X from "path";`（TypeScript の type import を許容。実装は名前空間 import を受理） — 解析: [Parser::parse_import_declaration()](src/ts_parser/parser.mbt:961)
- 型エイリアス:
  - `export type Name = { prop: QualifiedType; ... }`（メンバは `;` 区切り、末尾 `;` 任意）
- 関数宣言:
  - `export [async] function name(params...): ReturnType { ... }` — 解析: [Parser::parse_function_declaration()](src/ts_parser/parser.mbt:444)
  - 戻り型・パラメータ型は以下を許容: QualifiedType | TypeName | `Promise&lt;T&gt;` | `void`
- QualifiedType:
  - `Ident("." Ident)*`（例: `mbt.Int`, `foo.bar.Baz`） — 解析: [Parser::parse_qualified_name()](src/ts_parser/parser.mbt:335), 型引数: [Parser::parse_type_arguments()](src/ts_parser/parser.mbt:355)
- 関数本体はパース時にスキップ（型情報のみ抽出） — 実装: [Parser::skip_function_body()](src/ts_parser/parser.mbt:518)

### 3) 型マッピング（Moonbit 側）

- プリミティブ:
  - `number` → `Double`
  - `string` → `String`
  - `boolean` → `Bool`
  - `void` → `Unit`
- `mbt.` プレフィックスの特例（Moonbit ランタイム型のショートカット）:
  - `mbt.String` → `String`
  - `mbt.Int` → `Int`
  - `mbt.Float` → `Double`
  - `mbt.Void` → `Unit`
  - 上記以外の `mbt.Xxx` → `Xxx`（末尾名にフォールバック）、型引数は保持
  - 実装: [type_to_moonbit()](src/ts_parser/codegen.mbt:6)
- Promise:
  - `Promise&lt;T&gt;` → `Promise[map(T)]`（`map` は上記の Moonbit 型変換）
  - `async` 関数で戻りが既に `Promise&lt;T&gt;` の場合は二重 Promise にしない — 判定は [Parser::parse_function_declaration()](src/ts_parser/parser.mbt:444) で実施

### 4) 生成されるコード例（sample の要旨）

型エイリアス:

```moonbit
pub typealias Point = { x: Int; y: Int }
```

関数:

```moonbit
extern "js" fn add(a : Int, b : Int) -> Int = #|add|#
extern "js" fn distance(a : Point, b : Point) -> Double = #|distance|#
extern "js" fn readFile(path : String) -> Promise[String] = #|readFile|#
extern "js" fn writeFile(path : String, content : String) -> Promise[Unit] = #|writeFile|#
```

一括生成のエントリポイント: [generate_ffi_code()](src/ts_parser/codegen.mbt:293)

### 5) 実行/テスト

- すべてのテストは以下で実行可能:
  - ```bash
    moon test
    ```
- 代表テスト:
  - Qualified/Promise の解析:
    - [src/ts_parser/parser_qualified_test.mbt](src/ts_parser/parser_qualified_test.mbt)
    - [src/ts_parser/parser_promise_test.mbt](src/ts_parser/parser_promise_test.mbt)
    - [src/ts_parser/import_type_ns_test.mbt](src/ts_parser/import_type_ns_test.mbt)
  - 生成とマッピング:
    - [src/ts_parser/codegen_mbt_prefix_test.mbt](src/ts_parser/codegen_mbt_prefix_test.mbt)
  - サンプル統合:
    - [src/ts_parser/sample_bindings_integration_test.mbt](src/ts_parser/sample_bindings_integration_test.mbt)

### 6) 制限事項（今後の拡張候補）

- サブセット外:
  - 複雑なジェネリクス束縛、条件型、型演算
  - インターフェイス継承の詳細
  - 名前解決（import の型空間追跡などの厳密解決）
- codegen は当サブセット向けの最小変換に留める（Union/Intersection は簡略化など）— 実装の簡略化は [type_to_moonbit()](src/ts_parser/codegen.mbt:6) 内コメント参照
