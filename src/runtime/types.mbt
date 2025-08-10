// Common Runtime Interface
// This defines the common API that all runtime implementations should provide

///|
pub trait Runtime {
  // Console operations
  log(Self, message : String) -> Unit
  error(Self, message : String) -> Unit
  warn(Self, message : String) -> Unit
  info(Self, message : String) -> Unit
  debug(Self, message : String) -> Unit

  // Time operations
  now(Self) -> Int

  // Timer operations
  set_timeout(Self, callback : () -> Unit, ms : Int) -> Int
  set_interval(Self, callback : () -> Unit, ms : Int) -> Int
  clear_timeout(Self, id : Int) -> Unit
  clear_interval(Self, id : Int) -> Unit
}
