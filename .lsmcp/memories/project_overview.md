---
created: 2025-08-10T07:45:11.623Z
updated: 2025-08-10T07:45:11.623Z
---

# MoonBit Hello World プロジェクト

## プロジェクトの目的
このプロジェクトは MoonBit 言語で書かれたシンプルな "Hello, world!" プログラムです。MoonBit の基本的なプロジェクト構造とテストを示すサンプルプロジェクトです。

## 技術スタック
- **言語**: MoonBit (.mbt ファイル)
- **ビルドシステム**: Moon (MoonBit のビルドシステムとパッケージマネージャー)
- **ターゲット**: WebAssembly (wasm-gc)

## プロジェクト構造
```
study-mbt-20250810/
├── moon.mod.json       # モジュール定義ファイル
├── src/
│   ├── lib/           # ライブラリパッケージ
│   │   ├── hello.mbt      # hello関数の実装
│   │   ├── hello_test.mbt # テストファイル
│   │   └── moon.pkg.json  # パッケージ設定
│   └── main/          # メインパッケージ
│       ├── main.mbt       # エントリーポイント
│       └── moon.pkg.json  # パッケージ設定（is-main: true）
└── target/            # ビルド出力ディレクトリ

## モジュール情報
- **名前**: username/hello
- **バージョン**: 0.1.0
- **ライセンス**: Apache-2.0
- **ソースディレクトリ**: src

## 主要な機能
- `lib/hello.mbt`: `hello()` 関数が "Hello, world!" を返す
- `main/main.mbt`: `@lib.hello()` を呼び出してコンソールに出力
- `lib/hello_test.mbt`: hello関数の出力をテスト