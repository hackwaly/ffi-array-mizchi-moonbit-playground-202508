// Auto-generated MoonBit FFI bindings for JS backend

// Type definitions that would come from runtime
type JSValue
type Promise[T]

// Type alias with new syntax
typealias Double as UserID

// Generated struct for interface
pub struct User {
  value : JSValue
} derive(Show)

// Mock implementation for testing type checking
pub fn User::make(value : JSValue) -> User {
  { value }
}

// Accessor methods
pub fn User::id(self : User) -> Double {
  // In real implementation, this would call runtime's get method
  123.0 // mock value
}

pub fn User::name(self : User) -> String {
  // In real implementation, this would call runtime's get method
  "John" // mock value
}

pub fn User::email(self : User) -> String {
  // In real implementation, this would call runtime's get method  
  "john@example.com" // mock value
}

pub fn User::isActive(self : User) -> Bool {
  // In real implementation, this would call runtime's get method
  true // mock value
}

// For JS backend, extern "js" should work
// Note: This is commented out for wasm-gc compatibility
// extern "js" fn createUser(name : String, email : String) -> User = #|createUser|#
// extern "js" fn fetchUser(id : UserID) -> Promise[User] = #|fetchUser|#
// extern "js" fn getAllUsers() -> Array[User] = #|getAllUsers|#

// Mock implementations for type checking
pub fn createUser(name : String, email : String) -> User {
  println("Creating user: \{name}, \{email}")
  User::make(JSValue::default())
}

pub fn fetchUser(id : UserID) -> Promise[User] {
  println("Fetching user with id: \{id}")
  Promise::default()
}

pub fn getAllUsers() -> Array[User] {
  println("Getting all users")
  []
}

// Helper type implementations for testing
impl JSValue {
  pub fn default() -> JSValue {
    JSValue
  }
}

impl[T] Promise[T] {
  pub fn default() -> Promise[T] {
    Promise[T]
  }
}

// Test usage
test "ffi type checking" {
  let user = createUser("Alice", "alice@example.com")
  let id = user.id()
  let name = user.name()
  
  inspect(id, content="123")
  inspect(name, content="John")
  
  let user_id : UserID = 456.0
  let _promise = fetchUser(user_id)
  let users = getAllUsers()
  
  inspect(users.length(), content="0")
}