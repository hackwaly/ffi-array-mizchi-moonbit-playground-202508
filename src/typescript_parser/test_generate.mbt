// Test FFI generation directly in the parser package

test "generate FFI for basic interface" {
  let input = "export interface User { id: number; name: string; }"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_typescript_file()
  
  inspect(declarations.length(), content="1")
  
  let ffi = generate_ffi_code(declarations)
  inspect(ffi.contains("pub struct User"), content="true")
  inspect(ffi.contains("value : JSValue"), content="true")
}

test "generate FFI for function" {
  let input = "export function add(a: number, b: number): number"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_typescript_file()
  
  inspect(declarations.length(), content="1")
  
  let ffi = generate_ffi_code(declarations)
  inspect(ffi.contains("extern \"js\" fn add"), content="true")
  inspect(ffi.contains("(a : Double, b : Double)"), content="true")
  inspect(ffi.contains("-> Double"), content="true")
}

test "generate FFI for type alias" {
  let input = "export type UserID = number;"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_typescript_file()
  
  inspect(declarations.length(), content="1")
  
  let ffi = generate_ffi_code(declarations)
  inspect(ffi.contains("pub typealias Double as UserID"), content="true")
}

test "generate FFI for async function" {
  let input = "export function fetchUser(id: number): Promise<User>"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_typescript_file()
  
  inspect(declarations.length(), content="1")
  
  let ffi = generate_ffi_code(declarations)
  inspect(ffi.contains("extern \"js\" fn fetchUser"), content="true")
  inspect(ffi.contains("Promise[User]"), content="true")
}

test "generate FFI for complete example" {
  let input = 
    "export interface User { id: number; name: string; }\n" +
    "export type UserID = number;\n" +
    "export function createUser(name: string): User;\n" +
    "export function fetchUser(id: UserID): Promise<User>;"
  
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_typescript_file()
  
  inspect(declarations.length(), content="4")
  
  let ffi = generate_ffi_code(declarations)
  
  // Check header
  inspect(ffi.contains("Auto-generated FFI bindings"), content="true")
  
  // Check interface
  inspect(ffi.contains("pub struct User"), content="true")
  
  // Check type alias
  inspect(ffi.contains("pub typealias Double as UserID"), content="true")
  
  // Check functions
  inspect(ffi.contains("extern \"js\" fn createUser"), content="true")
  inspect(ffi.contains("extern \"js\" fn fetchUser"), content="true")
  
  // Print for visual inspection
  println("=== Generated FFI ===")
  println(ffi)
}