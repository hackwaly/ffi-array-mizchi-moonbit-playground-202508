// TypeScript型アノテーション除去のテスト - シンプルな実装から開始

test "parse simple function declaration" {
  let input = "function add(a: number, b: number): number {}"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  let result = parser.parse_declaration()
  match result {
    Some(Function(func)) => {
      inspect(func.name, content="add")
      inspect(func.params.length(), content="2")
    }
    _ => inspect(false, content="true")
  }
}

test "parse async function" {
  let input = "async function fetchData(url: string): Promise<string> {}"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  let result = parser.parse_declaration()
  match result {
    Some(Function(func)) => {
      inspect(func.name, content="fetchData")
      inspect(func.is_async, content="true")
    }
    _ => inspect(false, content="true")
  }
}

test "function with optional params" {
  let input = "function greet(name: string, title?: string): string {}"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  let result = parser.parse_declaration()
  match result {
    Some(Function(func)) => {
      inspect(func.params[0].optional, content="false")
      inspect(func.params[1].optional, content="true")
    }
    _ => inspect(false, content="true")
  }
}

test "function with rest params" {
  let input = "function sum(...numbers: number[]): number {}"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  let result = parser.parse_declaration()
  match result {
    Some(Function(func)) => {
      inspect(func.params[0].rest, content="true")
    }
    _ => inspect(false, content="true")
  }
}

test "generate FFI binding" {
  let input = "function multiply(x: number, y: number): number {}"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_declaration() {
    Some(Function(func)) => {
      let binding = generate_function_binding(func)
      inspect(binding.contains("extern \"js\" fn multiply"), content="true")
      inspect(binding.contains("Double"), content="true")
    }
    _ => inspect(false, content="true")
  }
}