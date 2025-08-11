// Test different approaches for ES module imports in MoonBit JS backend

type JSValue

// Approach 1: Try to inject module-level code
// This attempts to use a self-executing function, but it won't create actual imports
extern "js" fn inject_import() -> Unit =
  #| (() => {
  #|   // This runs at runtime, not at module level
  #|   console.log("This runs when inject_import is called");
  #| })()

// Approach 2: Reference to a symbol that would need to be imported
// This will generate: const func = someImportedFunction
// But won't generate the import statement
extern "js" fn use_imported_function(x : Int) -> Int =
  #| someImportedFunction

// Approach 3: Dynamic import (async)
extern "js" fn dynamic_import_module(path : String) -> JSValue =
  #| async (path) => {
  #|   const module = await import(path);
  #|   return module;
  #| }

// Approach 4: Check if we can reference module-level variables
extern "js" fn get_from_module() -> String =
  #| myModule.getValue()

fn main {
  println("Testing module import patterns...")
  
  // This will show that inject_import runs at call time, not module load time
  inject_import()
}