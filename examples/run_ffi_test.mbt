// Simple test to generate FFI from sample-api.d.ts

fn main {
  // サンプルファイルの内容を直接文字列として定義
  let sample_dts = 
    "// Basic interface\n" + 
    "export interface User {\n" +
    "  id: number;\n" +
    "  name: string;\n" +
    "  email: string;\n" +
    "  isActive: boolean;\n" +
    "}\n\n" +
    "// Type alias\n" +
    "export type UserID = number;\n" +
    "export type Status = \"pending\" | \"completed\" | \"failed\";\n\n" +
    "// Basic functions\n" +
    "export function createUser(name: string, email: string): User;\n" +
    "export function getUserById(id: UserID): User;\n\n" +
    "// Async function\n" +
    "export function fetchUser(id: UserID): Promise<User>;\n\n" +
    "// Function with object parameter\n" +
    "export function updateUser(id: UserID, data: { name?: string; email?: string }): User;"
  
  // Create lexer and parser
  let lexer = @typesrcipt_parser.Lexer::new(sample_dts)
  let parser = @typesrcipt_parser.Parser::new(lexer)
  
  // Parse the TypeScript declarations
  let declarations = parser.parse_typescript_file()
  
  println("=== Parsing Results ===")
  println("Parsed \{declarations.length()} declarations")
  
  // Print each declaration type
  for i = 0, len = declarations.length(); i < len; i = i + 1 {
    let decl = declarations[i]
    match decl {
      @typesrcipt_parser.Export(exp) => {
        match exp.declaration {
          Some(@typesrcipt_parser.Interface(iface)) => 
            println("  [\{i}] Export Interface: \{iface.name}")
          Some(@typesrcipt_parser.TypeAlias(ta)) => 
            println("  [\{i}] Export Type Alias: \{ta.name}")
          Some(@typesrcipt_parser.Function(func)) => 
            println("  [\{i}] Export Function: \{func.name}")
          _ => println("  [\{i}] Export (other)")
        }
      }
      @typesrcipt_parser.Interface(iface) => 
        println("  [\{i}] Interface: \{iface.name}")
      @typesrcipt_parser.TypeAlias(ta) => 
        println("  [\{i}] Type Alias: \{ta.name}")
      @typesrcipt_parser.Function(func) => 
        println("  [\{i}] Function: \{func.name}")
      _ => println("  [\{i}] Other declaration")
    }
  }
  
  // Generate FFI code
  println("\n=== Generating FFI Code ===")
  let ffi_code = @typesrcipt_parser.generate_ffi_code(declarations)
  
  println("\n=== Generated MoonBit FFI ===")
  println(ffi_code)
}