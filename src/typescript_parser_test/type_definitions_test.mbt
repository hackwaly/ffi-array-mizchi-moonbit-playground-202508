// Tests for converting TypeScript type definitions to MoonBit

test "convert simple type definitions to MoonBit" {
  let input = 
    "export type UserID = string;\n" +
    "export type ProductID = number;\n" +
    "export type IsActive = boolean;"
  
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_declarations()
  
  inspect(declarations.length(), content="3")
  
  let ffi_code = @typescript_parser.generate_ffi_code(declarations)
  
  // Check type aliases are generated correctly
  inspect(ffi_code.contains("pub typealias String as UserID"), content="true")
  inspect(ffi_code.contains("pub typealias Double as ProductID"), content="true")
  inspect(ffi_code.contains("pub typealias Bool as IsActive"), content="true")
}

test "convert object type definitions to MoonBit structs" {
  let input = 
    "export type User = {\n" +
    "  id: string;\n" +
    "  name: string;\n" +
    "  age: number;\n" +
    "};\n" +
    "export type Product = {\n" +
    "  id: string;\n" +
    "  price: number;\n" +
    "  inStock: boolean;\n" +
    "};"
  
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_declarations()
  
  inspect(declarations.length(), content="2")
  
  let ffi_code = @typescript_parser.generate_ffi_code(declarations)
  
  // Check structs are generated
  inspect(ffi_code.contains("pub struct User"), content="true")
  inspect(ffi_code.contains("pub struct Product"), content="true")
  
  // Check field accessors
  inspect(ffi_code.contains("pub fn User::id"), content="true")
  inspect(ffi_code.contains("pub fn User::name"), content="true")
  inspect(ffi_code.contains("pub fn User::age"), content="true")
  inspect(ffi_code.contains("pub fn Product::price"), content="true")
}

test "convert nested object types" {
  let input = 
    "export type Config = {\n" +
    "  api: {\n" +
    "    url: string;\n" +
    "    timeout: number;\n" +
    "  };\n" +
    "  debug: boolean;\n" +
    "};"
  
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_declarations()
  
  inspect(declarations.length(), content="1")
  
  let ffi_code = @typescript_parser.generate_ffi_code(declarations)
  
  // Check struct is generated
  inspect(ffi_code.contains("pub struct Config"), content="true")
  
  // Check field accessors
  inspect(ffi_code.contains("pub fn Config::api"), content="true")
  inspect(ffi_code.contains("pub fn Config::debug"), content="true")
}

test "convert union type definitions" {
  let input = 
    "export type Status = \"pending\" | \"processing\" | \"completed\" | \"failed\";\n" +
    "export type Result = { success: true; data: any } | { success: false; error: string };"
  
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_declarations()
  
  inspect(declarations.length(), content="2")
  
  let ffi_code = @typescript_parser.generate_ffi_code(declarations)
  
  // Union types are typically converted to Any in MoonBit FFI
  inspect(ffi_code.contains("pub typealias Any as Status"), content="true")
  inspect(ffi_code.contains("pub typealias Any as Result"), content="true")
}

test "convert array and optional types" {
  let input = 
    "export type IDs = string[];\n" +
    "export type MaybeNumber = number | undefined;"
  
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_declarations()
  
  inspect(declarations.length(), content="2")
  
  let ffi_code = @typescript_parser.generate_ffi_code(declarations)
  
  // Check array type
  inspect(ffi_code.contains("pub typealias Array[String] as IDs"), content="true")
  
  // Union with undefined becomes Any
  inspect(ffi_code.contains("pub typealias Any as MaybeNumber"), content="true")
}

test "complete type definitions file conversion" {
  let input = 
    "// Type definitions for a library\n" +
    "export type ID = string;\n" +
    "export type Timestamp = number;\n" +
    "\n" +
    "export type User = {\n" +
    "  id: ID;\n" +
    "  name: string;\n" +
    "  email: string;\n" +
    "  createdAt: Timestamp;\n" +
    "};\n" +
    "\n" +
    "export type Post = {\n" +
    "  id: ID;\n" +
    "  authorId: ID;\n" +
    "  title: string;\n" +
    "  content: string;\n" +
    "  publishedAt: Timestamp;\n" +
    "  tags: string[];\n" +
    "};\n" +
    "\n" +
    "export type ApiResponse<T> = {\n" +
    "  data: T;\n" +
    "  status: number;\n" +
    "  message: string;\n" +
    "};"
  
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_declarations()
  
  // Should parse at least the non-generic types
  inspect(declarations.length() >= 4, content="true")
  
  let ffi_code = @typescript_parser.generate_ffi_code(declarations)
  
  println("=== Generated MoonBit Code ===")
  println(ffi_code)
  
  // Check basic type aliases
  inspect(ffi_code.contains("pub typealias String as ID"), content="true")
  inspect(ffi_code.contains("pub typealias Double as Timestamp"), content="true")
  
  // Check structs
  inspect(ffi_code.contains("pub struct User"), content="true")
  inspect(ffi_code.contains("pub struct Post"), content="true")
  
  // Check field accessors
  inspect(ffi_code.contains("pub fn User::id"), content="true")
  inspect(ffi_code.contains("pub fn User::email"), content="true")
  inspect(ffi_code.contains("pub fn Post::title"), content="true")
  inspect(ffi_code.contains("pub fn Post::tags"), content="true")
}

test "convert empty object type" {
  let input = "export type Empty = {};"
  
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_declarations()
  
  inspect(declarations.length(), content="1")
  
  let ffi_code = @typescript_parser.generate_ffi_code(declarations)
  
  // Empty object should still generate a struct
  inspect(ffi_code.contains("pub struct Empty"), content="true")
  inspect(ffi_code.contains("value : JSValue"), content="true")
}

test "convert type with TypeReference" {
  let input = 
    "export type UserID = string;\n" +
    "export type AdminUser = {\n" +
    "  id: UserID;\n" +
    "  role: string;\n" +
    "  permissions: string[];\n" +
    "};"
  
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_declarations()
  
  inspect(declarations.length(), content="2")
  
  let ffi_code = @typescript_parser.generate_ffi_code(declarations)
  
  // Check type alias
  inspect(ffi_code.contains("pub typealias String as UserID"), content="true")
  
  // Check struct with type reference
  inspect(ffi_code.contains("pub struct AdminUser"), content="true")
  inspect(ffi_code.contains("pub fn AdminUser::id"), content="true")
  inspect(ffi_code.contains("pub fn AdminUser::permissions"), content="true")
}

test "convert readonly properties" {
  let input = 
    "export type ImmutableConfig = {\n" +
    "  readonly apiKey: string;\n" +
    "  readonly endpoint: string;\n" +
    "  timeout: number;\n" +
    "};"
  
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_declarations()
  
  inspect(declarations.length(), content="1")
  
  let ffi_code = @typescript_parser.generate_ffi_code(declarations)
  
  // Check struct is generated
  inspect(ffi_code.contains("pub struct ImmutableConfig"), content="true")
  
  // All properties should have accessors (readonly doesn't affect FFI generation)
  inspect(ffi_code.contains("pub fn ImmutableConfig::apiKey"), content="true")
  inspect(ffi_code.contains("pub fn ImmutableConfig::endpoint"), content="true")
  inspect(ffi_code.contains("pub fn ImmutableConfig::timeout"), content="true")
}