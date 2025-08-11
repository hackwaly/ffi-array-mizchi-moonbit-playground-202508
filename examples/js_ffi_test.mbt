// Test JS FFI with imports

// Test 1: Direct inline JS code
extern "js" fn inline_add(a : Int, b : Int) -> Int = 
  #| (a, b) => a + b

// Test 2: Using console object (global)
extern "js" fn console_log(msg : String) -> Unit =
  #| (msg) => console.log(msg)

// Test 3: Simulating import - this is what we want to achieve
// We want something like:
// import { someFunction } from './external-module.js'
// But how to express this in MoonBit?

// One possible approach - define the import at the top level
extern "js" fn get_imported_function() -> Any =
  #| () => {
  #|   // This would need to be at module level:
  #|   // import { someFunction } from './external-module.js';
  #|   // return someFunction;
  #|   
  #|   // For now, just return a placeholder
  #|   return () => "imported function placeholder";
  #| }

// Another approach - using dynamic import
extern "js" fn dynamic_import_module(path : String) -> Promise[Any] =
  #| (path) => import(path)

// Test function
pub fn test_js_ffi() -> Unit {
  let sum = inline_add(10, 20)
  console_log("Sum is: " + sum.to_string())
  
  // Test dynamic import approach
  let module_promise = dynamic_import_module("./some-module.js")
  console_log("Dynamic import initiated")
}

// What we ideally want to generate:
// 
// At the top of the generated JS file:
// import { createUser, fetchUser } from './api.js';
// 
// Then in the code:
// extern "js" fn createUser(name : String, email : String) -> User = 
//   #| createUser
// 
// extern "js" fn fetchUser(id : Int) -> Promise[User] =
//   #| fetchUser