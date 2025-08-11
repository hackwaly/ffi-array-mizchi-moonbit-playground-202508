// Simple JS FFI test to check generated output

// Basic FFI
extern "js" fn add(a : Int, b : Int) -> Int = 
  #| (a, b) => a + b

// Reference to external function (what we want to test)
extern "js" fn imported_func() -> String =
  #| externalFunction

// Another attempt - module reference
extern "js" fn module_func() -> String =
  #| api.someFunction

fn main {
  let result = add(1, 2)
  println(result.to_string())
}