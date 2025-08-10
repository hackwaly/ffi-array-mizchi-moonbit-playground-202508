// Simple test for TypeScript parser enhancements

test "skip string literals" {
  let input = "const x = \"test { }\" ; function foo(): void {}"
  let lexer = Lexer::new(input)
  
  // Should properly tokenize and skip string content
  let token1 = lexer.next_token()
  inspect(token1, content="Const")
  
  let token2 = lexer.next_token()
  inspect(token2, content="Identifier(\"x\")")
}

test "skip comments" {
  let input = "// comment\nfunction test() {}"
  let lexer = Lexer::new(input)
  
  // Skip whitespace should also skip comments
  let token = lexer.next_token()
  inspect(token, content="Function")
}

test "skip block comments" {
  let input = "/* multi\nline\ncomment */\ninterface Test {}"
  let lexer = Lexer::new(input)
  
  let token = lexer.next_token()
  inspect(token, content="Interface")
}

test "parse async function" {
  let input = "async function test(): Promise<void> {}"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  let decl = parser.parse_declaration()
  inspect(decl is Some(_), content="true")
}

test "skip function body" {
  let input = "function test() { const x = 1; return x + 2; }"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  let decl = parser.parse_declaration()
  match decl {
    Some(Function(func)) => {
      inspect(func.name, content="test")
    }
    _ => inspect(false, content="should be function")
  }
}