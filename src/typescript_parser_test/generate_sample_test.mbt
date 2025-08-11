// Test comprehensive FFI generation with sample API

test "generate FFI for comprehensive sample" {
  // サンプルファイルの内容（簡略版）
  let sample_dts = 
    "// Basic types and interfaces\n" +
    "export interface User {\n" +
    "  id: number;\n" +
    "  name: string;\n" +
    "  email: string;\n" +
    "  isActive: boolean;\n" +
    "}\n\n" +
    "export interface Product {\n" +
    "  id: number;\n" +
    "  name: string;\n" +
    "  price: number;\n" +
    "  inStock: boolean;\n" +
    "}\n\n" +
    "// Type aliases\n" +
    "export type UserID = number;\n" +
    "export type ProductID = number;\n" +
    "export type Status = \"pending\" | \"processing\" | \"completed\" | \"failed\";\n\n" +
    "// Functions\n" +
    "export function createUser(name: string, email: string): User;\n" +
    "export function updateUser(id: UserID, updates: Partial<User>): User;\n" +
    "export function deleteUser(id: UserID): boolean;\n" +
    "export function getAllUsers(): User[];\n\n" +
    "// Async functions\n" +
    "export function fetchUser(id: UserID): Promise<User>;\n" +
    "export function fetchProduct(id: ProductID): Promise<Product>;\n\n" +
    "// Object type parameter\n" +
    "export interface Config {\n" +
    "  apiUrl: string;\n" +
    "  timeout?: number;\n" +
    "  debug?: boolean;\n" +
    "}\n\n" +
    "export function createConfig(apiUrl: string, timeout?: number): Config;"
  
  // Create lexer and parser
  let lexer = Lexer::new(sample_dts)
  let parser = Parser::new(lexer)
  
  // Parse the TypeScript declarations
  let declarations = parser.parse_declarations()
  
  println("=== Parsing Results ===")
  println("Parsed \{declarations.length()} declarations\n")
  
  // Generate FFI code
  let ffi_code = @typescript_parser.generate_ffi_code(declarations)
  
  println("=== Generated MoonBit FFI ===")
  println(ffi_code)
  
  // 検証
  // インターフェース
  inspect(ffi_code.contains("pub struct User"), content="true")
  inspect(ffi_code.contains("pub struct Product"), content="true")
  inspect(ffi_code.contains("pub struct Config"), content="true")
  
  // 型エイリアス（新しい構文）
  inspect(ffi_code.contains("pub typealias Double as UserID"), content="true")
  inspect(ffi_code.contains("pub typealias Double as ProductID"), content="true")
  
  // 関数
  inspect(ffi_code.contains("extern \"js\" fn createUser"), content="true")
  inspect(ffi_code.contains("extern \"js\" fn updateUser"), content="true")
  inspect(ffi_code.contains("extern \"js\" fn deleteUser"), content="true")
  inspect(ffi_code.contains("extern \"js\" fn getAllUsers"), content="true")
  
  // Promiseを返す関数
  inspect(ffi_code.contains("extern \"js\" fn fetchUser"), content="true")
  inspect(ffi_code.contains("-> Promise[User]"), content="true")
  inspect(ffi_code.contains("extern \"js\" fn fetchProduct"), content="true")
  inspect(ffi_code.contains("-> Promise[Product]"), content="true")
  
  // オプショナルパラメータを持つ関数
  inspect(ffi_code.contains("extern \"js\" fn createConfig"), content="true")
}