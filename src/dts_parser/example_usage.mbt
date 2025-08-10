// Example usage of the TypeScript parser for FFI generation

test "parse and generate FFI for complex TypeScript" {
  let code = "export type APIConfig = { baseUrl: string; timeout: number; }"
  
  let lexer = Lexer::new(code)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_typescript_file()
  
  // Should parse export type declaration
  inspect(declarations.length() > 0, content="true")
  
  // Generate FFI code
  let ffi = generate_ffi_code(declarations)
  
  // Check that FFI code contains expected elements
  inspect(ffi.contains("Auto-generated"), content="true")
}

test "simple export function with object types" {
  let code = "export function foo(a: {x: number}, b: {y: string}): {z: boolean} { return {z: true}; }"
  
  let lexer = Lexer::new(code)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_typescript_file()
  
  inspect(declarations.length(), content="1")
  
  match declarations[0] {
    Export(exp) => {
      match exp.declaration {
        Some(Function(func)) => {
          inspect(func.name, content="foo")
          inspect(func.params.length(), content="2")
          // Check return type is object
          match func.return_type {
            Object(_) => inspect(true, content="true")
            _ => inspect(false, content="return type should be object")
          }
        }
        _ => inspect(false, content="should be function")
      }
    }
    _ => inspect(false, content="should be export")
  }
}

test "export type with nested objects" {
  let code = "export type Config = { api: { url: string; key: string }; cache: { ttl: number } }"
  
  let lexer = Lexer::new(code)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_typescript_file()
  
  inspect(declarations.length(), content="1")
  
  match declarations[0] {
    Export(exp) => {
      match exp.declaration {
        Some(TypeAlias(ta)) => {
          inspect(ta.name, content="Config")
          match ta.type_ {
            Object(_) => inspect(true, content="true")
            _ => inspect(false, content="should be object type")
          }
        }
        _ => inspect(false, content="should be type alias")
      }
    }
    _ => inspect(false, content="should be export")
  }
}