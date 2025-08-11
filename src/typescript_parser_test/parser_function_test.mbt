test "parser parses simple function declaration" {
  let input = "function greet(name: string): string"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_function_declaration() {
    Some(func) => {
      assert_eq(func.name, "greet")
      assert_eq(func.params.length(), 1)
      assert_eq(func.params[0].name, "name")
      match func.params[0].type_ {
        @typescript_parser.Type::String => assert_true(true)
        _ => assert_true(false)
      }
      match func.return_type {
        @typescript_parser.Type::String => assert_true(true)
        _ => assert_true(false)
      }
    }
    None => assert_true(false)
  }
}

test "parser parses function with multiple parameters" {
  let input = "function add(a: number, b: number): number"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_function_declaration() {
    Some(func) => {
      assert_eq(func.name, "add")
      assert_eq(func.params.length(), 2)
      
      assert_eq(func.params[0].name, "a")
      match func.params[0].type_ {
        @typescript_parser.Type::Number => assert_true(true)
        _ => assert_true(false)
      }
      
      assert_eq(func.params[1].name, "b")
      match func.params[1].type_ {
        @typescript_parser.Type::Number => assert_true(true)
        _ => assert_true(false)
      }
      
      match func.return_type {
        @typescript_parser.Type::Number => assert_true(true)
        _ => assert_true(false)
      }
    }
    None => assert_true(false)
  }
}

test "parser parses function with optional parameter" {
  let input = "function greet(name?: string): void"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_function_declaration() {
    Some(func) => {
      assert_eq(func.name, "greet")
      assert_eq(func.params.length(), 1)
      assert_eq(func.params[0].name, "name")
      assert_eq(func.params[0].optional, true)
      match func.params[0].type_ {
        @typescript_parser.Type::String => assert_true(true)
        _ => assert_true(false)
      }
      match func.return_type {
        @typescript_parser.Type::Void => assert_true(true)
        _ => assert_true(false)
      }
    }
    None => assert_true(false)
  }
}

test "parser parses exported function" {
  let input = "export function hello(): void"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_declaration() {
    Some(Export(export_decl)) => {
      match export_decl.declaration {
        Some(Function(func)) => {
          assert_eq(func.name, "hello")
          assert_eq(func.params.length(), 0)
          match func.return_type {
            @typescript_parser.Type::Void => assert_true(true)
            _ => assert_true(false)
          }
        }
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

test "parser parses function without return type" {
  let input = "function doSomething()"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_function_declaration() {
    Some(func) => {
      assert_eq(func.name, "doSomething")
      assert_eq(func.params.length(), 0)
      match func.return_type {
        @typescript_parser.Type::Void => assert_true(true)  // Default to void
        _ => assert_true(false)
      }
    }
    None => assert_true(false)
  }
}