// ES module import pattern exploration

type JSValue

// Approach 1: Dynamic import within FFI function
extern "js" fn dynamic_import_api() -> JSValue =
  #| async () => {
  #|   const { createUser } = await import('./api.js');
  #|   return { createUser };
  #| }

// Approach 2: Wrapper that expects global
extern "js" fn use_global_api(name : String) -> JSValue =
  #| (name) => {
  #|   // Assumes window.__api or globalThis.__api is set
  #|   if (typeof globalThis.__api === 'undefined') {
  #|     throw new Error('API not loaded. Please ensure api.js is imported');
  #|   }
  #|   return globalThis.__api.createUser(name);
  #| }

// Approach 3: Module loader pattern
extern "js" fn load_module(path : String) -> JSValue =
  #| async (path) => {
  #|   return await import(path);
  #| }

// Approach 4: Direct symbol reference (will fail without import)
extern "js" fn direct_create_user(name : String) -> JSValue =
  #| api.createUser

// Test main
fn main {
  println("Testing ES module import patterns...")
}