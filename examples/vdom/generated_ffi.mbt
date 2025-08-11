// Auto-generated MoonBit FFI bindings

// Required type definitions (usually from runtime)
type JSValue
type Promise[T]
type Any

// Helper types
pub typealias Partial[T] = T

// Generated FFI bindings

pub struct User {
  value : JSValue
}

pub fn User::id(self : User) -> Double {
  self.value.get("id")
}

pub fn User::name(self : User) -> String {
  self.value.get("name")
}

pub fn User::email(self : User) -> String {
  self.value.get("email")
}

pub fn User::isActive(self : User) -> Bool {
  self.value.get("isActive")
}

// Type alias: UserID
pub typealias UserID = Double

// Function bindings
extern "js" fn createUser(name : String, email : String) -> User = #|createUser|#

extern "js" fn fetchUser(id : UserID) -> Promise[User] = #|fetchUser|#

extern "js" fn getAllUsers() -> Array[User] = #|getAllUsers|#

// Test function to verify type checking
pub fn test_ffi_usage() -> Unit {
  // These should type check correctly
  let user = createUser("John", "john@example.com")
  let id = user.id()
  let name = user.name()
  let email = user.email()
  let is_active = user.isActive()
  
  let user_id : UserID = 123.0
  let promise = fetchUser(user_id)
  let users = getAllUsers()
  
  // Type assertions
  let _id_check : Double = id
  let _name_check : String = name
  let _email_check : String = email
  let _active_check : Bool = is_active
  let _promise_check : Promise[User] = promise
  let _users_check : Array[User] = users
}