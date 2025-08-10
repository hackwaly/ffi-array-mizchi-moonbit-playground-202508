// WebAssembly (legacy) backend implementation

pub struct Runtime {
  // Wasm runtime doesn't need any fields
}

pub fn Runtime::new() -> Runtime {
  Runtime::{}
}

// Public interface implementation
pub fn log(self : Runtime, message : String) -> Unit {
  // In a real implementation, this might use WASI or imported functions
  // For now, we use println which works in wasm
  println(message)
}

pub fn error(self : Runtime, message : String) -> Unit {
  println("ERROR: " + message)
}

pub fn now(self : Runtime) -> Int64 {
  // Return a dummy timestamp for now
  // In a real implementation, this would use WASI clock functions
  0L
}

// Tests
test "runtime can be created" {
  let runtime = Runtime::new()
  assert_true(true)
}

test "runtime can log" {
  let runtime = Runtime::new()
  runtime.log("test message from Wasm")
  assert_true(true)
}