// Auto-generated MoonBit FFI bindings (Fixed for type checking)

// Required type definitions (these would normally come from a runtime library)
pub type JSValue

// Mock get method for JSValue (実際のランタイムで提供される)
pub fn get[T](self : JSValue, key : String) -> T {
  // This would be implemented by the runtime
  abort("JSValue::get is a runtime function")
}

pub type Promise[T]
pub type Any

// Type alias with new syntax
pub typealias Double as UserID

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

// Function bindings for wasm backend
pub fn createUser(name : String, email : String) -> User {
  // Runtime implementation would go here
  abort("createUser is a runtime function")
}

pub fn fetchUser(id : UserID) -> Promise[User] {
  // Runtime implementation would go here
  abort("fetchUser is a runtime function")
}

pub fn getAllUsers() -> Array[User] {
  // Runtime implementation would go here
  abort("getAllUsers is a runtime function")
}

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
  
  println("Type checking passed!")
}