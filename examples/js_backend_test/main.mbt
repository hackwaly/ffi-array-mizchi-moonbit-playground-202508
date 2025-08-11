// Test JS backend FFI features

// Type definitions
type JSValue
type Promise[T]

// Test different FFI patterns

// Pattern 1: Direct inline function
extern "js" fn add(a : Double, b : Double) -> Double =
  #| (a, b) => a + b

// Pattern 2: Reference to global object method
extern "js" fn log(message : String) -> Unit =
  #| console.log

// Pattern 3: Multi-line JS with local variables
extern "js" fn fetch_json(url : String) -> Promise[JSValue] =
  #| async (url) => {
  #|   const response = await fetch(url);
  #|   return response.json();
  #| }

// Pattern 4: What we want - reference to imported symbol
// This is what we're trying to achieve:
// import { api } from './api.js';
// then use: api.createUser

// Attempt 1: Direct reference (will this work?)
// extern "js" fn create_user_from_import(name : String) -> JSValue =
//   #| createUser  // This assumes createUser is in scope

// Attempt 2: Module-level code injection
// Can we inject import statements at module level?
extern "js" fn setup_imports() -> Unit =
  #| () => {
  #|   // This executes at runtime, not what we want
  #|   globalThis.__imported_createUser = (name) => ({ id: 1, name });
  #| }

// Attempt 3: Using a module pattern
extern "js" fn get_api_module() -> JSValue =
  #| (() => {
  #|   // Simulate module - but we want real ES modules
  #|   return {
  #|     createUser: (name) => ({ id: Math.random(), name }),
  #|     fetchUser: (id) => Promise.resolve({ id, name: "User" + id })
  #|   };
  #| })()

fn main {
  // Test basic FFI
  let sum = add(1.0, 2.0)
  log("Sum: " + sum.to_string())
  
  // Test module access
  let api = get_api_module()
  log("API module obtained")
}