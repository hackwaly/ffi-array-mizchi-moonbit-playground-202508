# Runtime - JavaScript/WASM相互運用層

MoonBitとJavaScript/Node.js/Deno環境との相互運用を提供するランタイム層。

## 機能

### FFIバインディング
- JavaScript関数の呼び出し
- Promise/async関数のサポート
- イベントハンドリング
- コールバック関数

### ランタイム検出
異なるJavaScript環境を検出して適切なAPIを使用:
- Node.js
- Deno
- ブラウザ
- Web Worker

### 標準API

#### Console
```moonbit
extern "js" fn console_log(message : String) -> Unit = #|console.log|#
extern "js" fn console_error(message : String) -> Unit = #|console.error|#
```

#### Timer
```moonbit
extern "js" fn setTimeout(callback : () -> Unit, delay : Int) -> Int = #|setTimeout|#
extern "js" fn clearTimeout(id : Int) -> Unit = #|clearTimeout|#
```

#### Promise
```moonbit
pub struct Promise[T] {
  // JavaScript Promise wrapper
}

extern "js" fn create_promise[T](
  executor : (resolve : (T) -> Unit, reject : (String) -> Unit) -> Unit
) -> Promise[T] = #|new Promise|#
```

### 型マッピング

| MoonBit | JavaScript |
|---------|------------|
| String | string |
| Int | number (integer) |
| Double | number (float) |
| Bool | boolean |
| Unit | undefined/void |
| Array[T] | T[] |
| Map[K, V] | Map<K, V> |
| Promise[T] | Promise<T> |

## 使用例

### 基本的なFFI

```moonbit
// JavaScript関数の宣言
extern "js" fn fetch(url : String) -> Promise[Response] = #|fetch|#

// 使用
pub fn get_data(url : String) -> Promise[String] {
  fetch(url).then(fn(response) {
    response.text()
  })
}
```

### ランタイム検出

```moonbit
pub fn detect_runtime() -> RuntimeType {
  if is_deno() {
    Deno
  } else if is_node() {
    NodeJS
  } else if is_browser() {
    Browser
  } else {
    Unknown
  }
}
```

### イベントハンドリング

```moonbit
extern "js" fn addEventListener(
  event : String,
  handler : (Event) -> Unit
) -> Unit = #|addEventListener|#

pub fn setup_click_handler() -> Unit {
  addEventListener("click", fn(event) {
    console_log("Clicked!")
  })
}
```

## ビルド設定

### WASM向け
```bash
moon build --target wasm
```

### JavaScript向け
```bash
moon build --target js
```

## テスト

```bash
moon test src/runtime
```

## 注意事項

- FFIを使用する際は型安全性に注意
- JavaScriptの`null`/`undefined`の扱いに注意
- 非同期処理のエラーハンドリングを適切に行う