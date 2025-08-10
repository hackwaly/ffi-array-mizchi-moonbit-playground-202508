///| JavaScript Promise ラッパー for MoonBit (async/suspend)
#external
pub type JsPromise

///|
#external
pub type JSAny

///| JSAny <-> String の簡易ブリッジ
pub extern "js" fn js_value_of_string(s : String) -> JSAny =
  #| (s) => s

///|
pub extern "js" fn js_string_of_value(v : JSAny) -> String =
  #| (v) => String(v)

///| suspend プリミティブ（本モジュール内でも宣言）
async fn[T, E : Error] suspend(
  f : ((T) -> Unit, (E) -> Unit) -> Unit,
) -> T raise E = "%async.suspend"

///| Promise.new の FFI
extern "js" fn js_promise_new(
  executor : ((JSAny) -> Unit, (JSAny) -> Unit) -> Unit,
) -> JsPromise =
  #| (executor) => new Promise((resolve, reject) => executor(resolve, reject))

///| Promise.resolve / reject
extern "js" fn js_promise_resolve(value : JSAny) -> JsPromise =
  #| (v) => Promise.resolve(v)

///|
extern "js" fn js_promise_reject(reason : JSAny) -> JsPromise =
  #| (e) => Promise.reject(e)

///| then / catch
extern "js" fn js_promise_then(
  promise : JsPromise,
  on_fulfilled : (JSAny) -> JSAny,
) -> JsPromise =
  #| (p, f) => p.then(f)

///|
extern "js" fn js_promise_catch(
  promise : JsPromise,
  on_rejected : (JSAny) -> JSAny,
) -> JsPromise =
  #| (p, f) => p.catch(f)

///| resolve/reject を横取りして MoonBit の resume を呼ぶためのタップ
extern "js" fn js_promise_tap(
  promise : JsPromise,
  on_fulfilled : (JSAny) -> Unit,
  on_rejected : (JSAny) -> Unit,
) -> Unit =
  #| (p, ok, err) => { p.then(v => { ok(v); return v; }).catch(e => { err(e); return e; }); }

///| 公開 API
pub fn new_promise(
  executor : ((JSAny) -> Unit, (JSAny) -> Unit) -> Unit,
) -> JsPromise {
  js_promise_new(executor)
}

///|
pub fn resolve(value : JSAny) -> JsPromise {
  js_promise_resolve(value)
}

///|
pub fn reject(reason : JSAny) -> JsPromise {
  js_promise_reject(reason)
}

///|
pub fn then(promise : JsPromise, on_fulfilled : (JSAny) -> JSAny) -> JsPromise {
  js_promise_then(promise, on_fulfilled)
}

///|
pub fn catch_error(
  promise : JsPromise,
  on_rejected : (JSAny) -> JSAny,
) -> JsPromise {
  js_promise_catch(promise, on_rejected)
}

///| Promise を suspend で待機する
pub suberror JsPromiseError

///|
pub async fn await_js(promise : JsPromise) -> JSAny raise JsPromiseError {
  suspend(fn(res_ok, res_err) {
    js_promise_tap(promise, fn(v) { res_ok(v) }, fn(_e) {
      res_err(JsPromiseError)
    })
  })
}

///| Promise(JSAny) を String として受け取るユーティリティ
pub async fn await_string(p : JsPromise) -> String raise JsPromiseError {
  let v = await_js(p)
  js_string_of_value(v)
}

///| Promise を decode 関数で値に落とす汎用ヘルパ
pub async fn[T] await_map(
  p : JsPromise,
  decode : (JSAny) -> T,
) -> T raise JsPromiseError {
  let v = await_js(p)
  decode(v)
}

///| Promise を返すJS関数 f(A) を await + decode する汎用ヘルパ
pub async fn[A, T] await1(
  f : (A) -> JsPromise,
  a : A,
  decode : (JSAny) -> T,
) -> T raise JsPromiseError {
  await_map(f(a), decode)
}

///| Promise を返すJS関数 f(A,B) を await + decode する汎用ヘルパ
pub async fn[A, B, T] await2(
  f : (A, B) -> JsPromise,
  a : A,
  b : B,
  decode : (JSAny) -> T,
) -> T raise JsPromiseError {
  await_map(f(a, b), decode)
}

//// 使用例は examples パッケージへ移動: [src/examples/promise_examples.mbt](src/examples/promise_examples.mbt)
