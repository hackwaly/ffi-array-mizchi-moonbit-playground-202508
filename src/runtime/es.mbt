// ES Module Runtime FFI Bindings (Universal JavaScript Environment)

// Core Types

///|
pub type Promise[T]

///|
pub struct ESRuntime {}

// Console Functions

///|
extern "js" fn js_log(message : String) -> Unit =
  #| (message) => console.log(message)

///|
extern "js" fn js_error(message : String) -> Unit =
  #| (message) => console.error(message)

///|
extern "js" fn js_warn(message : String) -> Unit =
  #| (message) => console.warn(message)

///|
extern "js" fn js_info(message : String) -> Unit =
  #| (message) => console.info(message)

///|
extern "js" fn js_debug(message : String) -> Unit =
  #| (message) => console.debug(message)

// Time Functions

///|
extern "js" fn js_now() -> Int =
  #| () => Date.now()

///|
extern "js" fn js_performance_now() -> Double =
  #| () => performance.now()

// Promise Operations
// Note: Generic type parameters are not supported in FFI functions

///|
extern "js" fn js_promise_reject(error : String) -> Promise[Unit] =
  #| (error) => Promise.reject(new Error(error))

// Timers

///|
extern "js" fn js_set_timeout(callback : () -> Unit, ms : Int) -> Int =
  #| (callback, ms) => setTimeout(callback, ms)

///|
extern "js" fn js_set_interval(callback : () -> Unit, ms : Int) -> Int =
  #| (callback, ms) => setInterval(callback, ms)

///|
extern "js" fn js_clear_timeout(id : Int) -> Unit =
  #| (id) => clearTimeout(id)

///|
extern "js" fn js_clear_interval(id : Int) -> Unit =
  #| (id) => clearInterval(id)

///|
extern "js" fn js_set_immediate(callback : () -> Unit) -> Unit =
  #| (callback) => {
  #|   setTimeout(callback, 0);
  #| }

// Response type for fetch API

///|
pub type Response

// Fetch API

///|
extern "js" fn js_fetch(url : String) -> Promise[Response] =
  #| (url) => fetch(url)

///|
extern "js" fn js_fetch_with_options(
  url : String,
  options : String,
) -> Promise[Response] =
  #| (url, options) => fetch(url, JSON.parse(options))

///|
extern "js" fn js_response_text(response : Response) -> Promise[String] =
  #| (response) => response.text()

///|
extern "js" fn js_response_json(response : Response) -> Promise[String] =
  #| async (response) => JSON.stringify(await response.json())

///|
extern "js" fn js_response_status(response : Response) -> Int =
  #| (response) => response.status

///|
extern "js" fn js_response_ok(response : Response) -> Bool =
  #| (response) => response.ok

///|
extern "js" fn js_response_headers(response : Response) -> String =
  #| (response) => JSON.stringify(Object.fromEntries(response.headers.entries()))

///|
extern "js" fn js_await_response(promise : Promise[Response]) -> Response =
  #| async (promise) => {
  #|   try {
  #|     return await promise;
  #|   } catch (error) {
  #|     console.error('Fetch error:', error);
  #|     return { ok: false, status: 0, text: () => Promise.resolve('Network error'), json: () => Promise.reject('Network error') };
  #|   }
  #| }

///|
extern "js" fn js_await_string(promise : Promise[String]) -> String =
  #| async (promise) => {
  #|   try {
  #|     return await promise;
  #|   } catch (error) {
  #|     return 'Error: ' + error.toString();
  #|   }
  #| }

// JSON Operations

///|
extern "js" fn js_json_stringify(obj : String) -> String =
  #| (obj) => JSON.stringify(obj)

///|
extern "js" fn js_json_parse(json : String) -> String =
  #| (json) => JSON.parse(json)

// Runtime Detection

// Runtime Implementation

///|
pub fn ESRuntime::new() -> ESRuntime {
  ESRuntime::{  }
}

// Console Methods

///|
pub fn console_log(self : ESRuntime, message : String) -> Unit {
  js_log(message)
}

///|
pub fn console_error(self : ESRuntime, message : String) -> Unit {
  js_error(message)
}

///|
pub fn console_warn(self : ESRuntime, message : String) -> Unit {
  js_warn(message)
}

///|
pub fn console_info(self : ESRuntime, message : String) -> Unit {
  js_info(message)
}

///|
pub fn console_debug(self : ESRuntime, message : String) -> Unit {
  js_debug(message)
}

// Time Methods

///|
pub fn date_now(self : ESRuntime) -> Int {
  js_now()
}

///|
pub fn performance_now(self : ESRuntime) -> Double {
  js_performance_now()
}

// Promise Methods
// Note: Generic promise operations removed due to FFI limitations

///|
pub fn promise_reject(_self : ESRuntime, error : String) -> Promise[Unit] {
  js_promise_reject(error)
}

// Timer Methods

///|
pub fn set_timeout(self : ESRuntime, callback : () -> Unit, ms : Int) -> Int {
  js_set_timeout(callback, ms)
}

///|
pub fn set_interval(self : ESRuntime, callback : () -> Unit, ms : Int) -> Int {
  js_set_interval(callback, ms)
}

///|
pub fn clear_timeout(self : ESRuntime, id : Int) -> Unit {
  js_clear_timeout(id)
}

///|
pub fn clear_interval(self : ESRuntime, id : Int) -> Unit {
  js_clear_interval(id)
}

///|
pub fn set_immediate(self : ESRuntime, callback : () -> Unit) -> Unit {
  js_set_immediate(callback)
}

// Fetch Methods - Low Level

///|
pub fn fetch(_self : ESRuntime, url : String) -> Promise[Response] {
  js_fetch(url)
}

///|
pub fn fetch_with_options(
  _self : ESRuntime,
  url : String,
  options : String,
) -> Promise[Response] {
  js_fetch_with_options(url, options)
}

// Response Methods

///|
pub fn response_text(_self : ESRuntime, response : Response) -> Promise[String] {
  js_response_text(response)
}

///|
pub fn response_json(_self : ESRuntime, response : Response) -> Promise[String] {
  js_response_json(response)
}

///|
pub fn response_status(_self : ESRuntime, response : Response) -> Int {
  js_response_status(response)
}

///|
pub fn response_ok(_self : ESRuntime, response : Response) -> Bool {
  js_response_ok(response)
}

///|
pub fn response_headers(_self : ESRuntime, response : Response) -> String {
  js_response_headers(response)
}

// Await Methods

///|
pub fn await_response(
  _self : ESRuntime,
  promise : Promise[Response],
) -> Response {
  js_await_response(promise)
}

///|
pub fn await_string(_self : ESRuntime, promise : Promise[String]) -> String {
  js_await_string(promise)
}

// High Level Fetch Methods

///|
pub fn fetch_text(_self : ESRuntime, url : String) -> String {
  let response_promise = js_fetch(url)
  let response = js_await_response(response_promise)
  if js_response_ok(response) {
    let text_promise = js_response_text(response)
    js_await_string(text_promise)
  } else {
    let status = js_response_status(response)
    "Error: HTTP \{status}"
  }
}

///|
pub fn fetch_json_string(_self : ESRuntime, url : String) -> String {
  let response_promise = js_fetch(url)
  let response = js_await_response(response_promise)
  if js_response_ok(response) {
    let json_promise = js_response_json(response)
    js_await_string(json_promise)
  } else {
    let status = js_response_status(response)
    "{ \"error\": \"HTTP \{status}\" }"
  }
}

///|
pub fn post_json(_self : ESRuntime, url : String, data : String) -> String {
  let options = "{ \"method\": \"POST\", \"headers\": { \"Content-Type\": \"application/json\" }, \"body\": \{data} }"
  let response_promise = js_fetch_with_options(url, options)
  let response = js_await_response(response_promise)
  if js_response_ok(response) {
    let text_promise = js_response_text(response)
    js_await_string(text_promise)
  } else {
    let status = js_response_status(response)
    "POST failed with status \{status}"
  }
}

// JSON Methods

///|
pub fn json_stringify(self : ESRuntime, obj : String) -> String {
  js_json_stringify(obj)
}

///|
pub fn json_parse(self : ESRuntime, json : String) -> String {
  js_json_parse(json)
}

// Runtime Detection Methods
