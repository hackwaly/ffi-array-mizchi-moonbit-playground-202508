// Type checking tests - シンプルな実装から開始

test "parse and generate interface FFI" {
  let input = "export interface Point { x: number; y: number; }"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  let declarations = parser.parse_typescript_file()
  inspect(declarations.length(), content="1")
  
  let ffi = generate_ffi_code(declarations)
  
  // 生成されたコードに必要な要素が含まれているか確認
  inspect(ffi.contains("pub struct Point"), content="true")
  inspect(ffi.contains("value : JSValue"), content="true")
  inspect(ffi.contains("pub fn Point::x"), content="true")
  inspect(ffi.contains("pub fn Point::y"), content="true")
}

test "parse and generate type alias FFI" {
  let input = "export type UserID = number;"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  let declarations = parser.parse_typescript_file()
  let ffi = generate_ffi_code(declarations)
  
  // typealias が生成されているか確認
  inspect(ffi.contains("pub typealias UserID"), content="true")
  inspect(ffi.contains("Double"), content="true")
}

test "parse and generate function FFI" {
  let input = "export function createUser(name: string, age: number): void {}"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  let declarations = parser.parse_typescript_file()
  let ffi = generate_ffi_code(declarations)
  
  // 関数バインディングが生成されているか確認
  inspect(ffi.contains("extern \"js\" fn createUser"), content="true")
  inspect(ffi.contains("String"), content="true")
  inspect(ffi.contains("Double"), content="true")
  inspect(ffi.contains("Unit"), content="true")
}

test "parse and generate class FFI" {
  let input = "export class User { name: string; age: number; }"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  let declarations = parser.parse_typescript_file()
  let ffi = generate_ffi_code(declarations)
  
  // クラスの構造体とアクセサが生成されているか確認
  inspect(ffi.contains("pub struct User"), content="true")
  inspect(ffi.contains("pub fn User::name"), content="true")
  inspect(ffi.contains("pub fn User::age"), content="true")
}

test "generate complex interface with methods" {
  let input = "export interface Calculator { add(a: number, b: number): number; }"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  let declarations = parser.parse_typescript_file()
  let ffi = generate_ffi_code(declarations)
  
  // インターフェースのメソッドが生成されているか確認
  inspect(ffi.contains("pub struct Calculator"), content="true")
  inspect(ffi.contains("pub fn Calculator::add"), content="true")
  inspect(ffi.contains("Double"), content="true")
}

test "generate Promise return type" {
  let input = "export function fetchData(): Promise<string> {}"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  let declarations = parser.parse_typescript_file()
  let ffi = generate_ffi_code(declarations)
  
  // Promise型が正しく変換されているか確認
  inspect(ffi.contains("extern \"js\" fn fetchData"), content="true")
  inspect(ffi.contains("Promise[String]"), content="true")
}

test "generate optional parameters" {
  let input = "export function greet(name: string, title?: string): void {}"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  let declarations = parser.parse_typescript_file()
  let ffi = generate_ffi_code(declarations)
  
  // オプショナルパラメータが生成されているか確認
  inspect(ffi.contains("extern \"js\" fn greet"), content="true")
  inspect(ffi.contains("String?"), content="true")
}

test "generate array types" {
  let input = "export function processItems(items: string[]): number[] {}"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  let declarations = parser.parse_typescript_file()
  let ffi = generate_ffi_code(declarations)
  
  // 配列型が正しく変換されているか確認
  inspect(ffi.contains("extern \"js\" fn processItems"), content="true")
  inspect(ffi.contains("Array[String]"), content="true")
  inspect(ffi.contains("Array[Double]"), content="true")
}

test "generate union type as Any" {
  let input = "export function handle(value: string | number): void {}"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  let declarations = parser.parse_typescript_file()
  let ffi = generate_ffi_code(declarations)
  
  // Union型がAnyに変換されているか確認
  inspect(ffi.contains("extern \"js\" fn handle"), content="true")
  inspect(ffi.contains("Any"), content="true")
}

test "parse multiple declarations" {
  let input = "export interface A { x: number; } export function foo(): void {}"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  let declarations = parser.parse_typescript_file()
  inspect(declarations.length(), content="2")
  
  let ffi = generate_ffi_code(declarations)
  
  // 両方の宣言が生成されているか確認
  inspect(ffi.contains("pub struct A"), content="true")
  inspect(ffi.contains("extern \"js\" fn foo"), content="true")
}