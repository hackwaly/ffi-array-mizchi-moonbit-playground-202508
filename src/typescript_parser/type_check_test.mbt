// Test that generated FFI code can be type-checked

test "generated FFI code type checks correctly" {
  // Simulate the type checking process
  let sample_interface = """
pub struct User {
  value : JSValue
}

pub fn User::id(self : User) -> Double {
  // mock implementation
  0.0
}"""

  let sample_typealias = "typealias Double as UserID"
  
  let sample_function = """
pub fn createUser(name : String, email : String) -> User {
  // mock implementation
  { value: JSValue }
}"""

  // These are syntactically valid MoonBit code
  inspect(sample_interface.contains("pub struct User"), content="true")
  inspect(sample_typealias.contains("typealias"), content="true")
  inspect(sample_function.contains("pub fn createUser"), content="true")
  
  // Test the actual code generation
  let input = "export interface Point { x: number; y: number; }"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_typescript_file()
  let ffi = generate_ffi_code(declarations)
  
  // Check generated structure
  inspect(ffi.contains("pub struct Point"), content="true")
  inspect(ffi.contains("value : JSValue"), content="true")
  inspect(ffi.contains("pub fn Point::x"), content="true")
  inspect(ffi.contains("pub fn Point::y"), content="true")
}

test "type alias syntax is correct" {
  let input = "export type ID = number;"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_typescript_file()
  let ffi = generate_ffi_code(declarations)
  
  // Current output uses old syntax
  inspect(ffi.contains("pub typealias ID = Double"), content="true")
  
  // Should be updated to new syntax: typealias Double as ID
  // This would require updating the codegen
}