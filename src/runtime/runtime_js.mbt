// JavaScript backend implementation

pub struct Runtime {
  // JS runtime doesn't need any fields
}

pub fn Runtime::new() -> Runtime {
  Runtime::{}
}

// JS-specific FFI functions
extern "js" fn js_console_log(message : String) -> Unit =
  #| (message) => console.log(message)

extern "js" fn js_console_error(message : String) -> Unit =
  #| (message) => console.error(message)

extern "js" fn js_date_now() -> Int64 =
  #| () => BigInt(Date.now())

// Public interface implementation
pub fn log(self : Runtime, message : String) -> Unit {
  js_console_log(message)
}

pub fn error(self : Runtime, message : String) -> Unit {
  js_console_error(message)
}

pub fn now(self : Runtime) -> Int64 {
  js_date_now()
}

// Tests
test "runtime can be created" {
  let runtime = Runtime::new()
  assert_true(true)
}

test "runtime can log" {
  let runtime = Runtime::new()
  runtime.log("test message from JS")
  assert_true(true)
}