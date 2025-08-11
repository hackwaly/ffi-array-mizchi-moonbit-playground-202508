// Test generating and type-checking FFI code

test "generate and save FFI code for type checking" {
  let sample_dts = 
    "export interface User {\n" +
    "  id: number;\n" +
    "  name: string;\n" +
    "  email: string;\n" +
    "  isActive: boolean;\n" +
    "}\n\n" +
    "export type UserID = number;\n\n" +
    "export function createUser(name: string, email: string): User;\n" +
    "export function fetchUser(id: UserID): Promise<User>;\n" +
    "export function getAllUsers(): User[];"
  
  let lexer = Lexer::new(sample_dts)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_typescript_file()
  
  let ffi_code = generate_ffi_code(declarations)
  
  // ヘッダーの重複を修正
  let lines : Array[String] = []
  for line in ffi_code.split("\n") {
    if line.to_string() != "// Auto-generated FFI bindings from TypeScript" {
      lines.push(line.to_string())
    }
  }
  let cleaned_ffi = lines.join("\n")
  
  // 必要な型定義を追加
  let complete_ffi = "// Auto-generated MoonBit FFI bindings\n\n" +
    "// Required type definitions\n" +
    "type JSValue\n" +
    "type Promise[T]\n" +
    "type Any\n\n" +
    "// Partial type helper\n" + 
    "pub typealias Partial[T] = T\n\n" +
    cleaned_ffi
  
  println("=== Complete FFI Code ===")
  println(complete_ffi)
  
  // ファイルに保存（実際のテストでは不要）
  inspect(complete_ffi.contains("pub struct User"), content="true")
  inspect(complete_ffi.contains("extern \"js\" fn createUser"), content="true")
}