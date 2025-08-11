// Generate MoonBit FFI bindings from sample-api.d.ts

fn main {
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
  let lexer = @typescript_parser.Lexer::new(sample_dts)
  let parser = @typescript_parser.Parser::new(lexer)
  
  // Parse the TypeScript declarations
  let declarations = parser.parse_typescript_file()
  
  println("=== Parsing Results ===")
  println("Parsed \{declarations.length()} declarations\n")
  
  // Generate FFI code
  let ffi_code = @typescript_parser.generate_ffi_code(declarations)
  
  println("=== Generated MoonBit FFI ===")
  println(ffi_code)
  
  // 生成されたコードをファイルに保存
  let output_path = "generated_sample_api.mbt"
  @fs.write_string_to_file?(output_path, ffi_code)
  
  println("\n=== Output saved to \{output_path} ===")
}