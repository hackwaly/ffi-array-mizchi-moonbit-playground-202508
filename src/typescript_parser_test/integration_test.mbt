// Integration tests for the TypeScript parser

test "parse simple TypeScript function" {
  let code = "function hello(name: string): string { return 'Hello ' + name; }"
  let lexer = Lexer::new(code)
  let parser = Parser::new(lexer)
  let declarations = parser.parse()
  
  inspect(declarations.length() > 0, content="true")
}

test "parse TypeScript with comments" {
  let code = "// This is a comment\n/* Block comment */\nfunction test() {}"
  let lexer = Lexer::new(code)
  let parser = Parser::new(lexer)
  let declarations = parser.parse()
  
  inspect(declarations.length() > 0, content="true")
}

test "parse interface declaration" {
  let code = "interface Point { x: number; y: number; }"
  let lexer = Lexer::new(code)
  let parser = Parser::new(lexer)
  let declarations = parser.parse()
  
  inspect(declarations.length(), content="1")
}

test "parse class with methods" {
  let code = "class Calculator { add(a: number, b: number): number { return a + b; } }"
  let lexer = Lexer::new(code)
  let parser = Parser::new(lexer)
  let declarations = parser.parse()
  
  inspect(declarations.length(), content="1")
}

test "parse async function declaration" {
  let code = "async function getData(): Promise<string> { return await fetch('/api'); }"
  let lexer = Lexer::new(code)
  let parser = Parser::new(lexer)
  let declarations = parser.parse()
  
  inspect(declarations.length(), content="1")
}

test "parse export declaration" {
  let code = "export function publicAPI() { return 42; }"
  let lexer = Lexer::new(code)
  let parser = Parser::new(lexer)
  let declarations = parser.parse()
  
  inspect(declarations.length(), content="1")
}

test "parse variable declaration with type" {
  let code = "const PI: number = 3.14159"
  let lexer = Lexer::new(code)
  let parser = Parser::new(lexer)
  let declarations = parser.parse()
  
  inspect(declarations.length(), content="1")
}

test "skip complex nested structures" {
  let code = "function test() { const obj = { nested: { deep: { value: 123 } } }; return obj; }"
  let lexer = Lexer::new(code)
  let parser = Parser::new(lexer)
  let declarations = parser.parse()
  
  inspect(declarations.length() > 0, content="true")
}

test "handle string literals with special chars" {
  let code = "const str = \"This has { } and ( )\""
  let lexer = Lexer::new(code)
  let parser = Parser::new(lexer)
  let declarations = parser.parse()
  
  inspect(declarations.length() > 0, content="true")
}

test "parse multiple declarations in file" {
  let code = "interface A {} function b() {} class C {}"
  let lexer = Lexer::new(code)
  let parser = Parser::new(lexer)
  let declarations = parser.parse()
  
  inspect(declarations.length(), content="3")
}