# mizchi/esmbt

ES Module Runtime FFI Bindings for MoonBit - JavaScript相互運用ライブラリ

## 概要

`esmbt`は、MoonBitからJavaScriptランタイムの機能にアクセスするためのFFI（Foreign Function Interface）バインディングを提供するライブラリです。ES Modules環境で動作し、Deno、Node.js、ブラウザなど複数のランタイムをサポートします。

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
新しいMoonBit + JavaScript相互運用プロジェクトを生成するCLIツール

```bash
./mbt-init.ts my-project --runtime=es
```

### mbtrun.ts
MoonBitファイルを直接実行するDenoラッパー

```bash
./mbtrun.ts my-script.mbt
```

## ライセンス

MIT