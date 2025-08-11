test "lexer tokenizes single identifier" {
  let input = "hello"
  let lexer = Lexer::new(input)
  
  match lexer.next_token() {
    Identifier(name) => assert_eq(name, "hello")
    _ => assert_true(false)
  }
  match lexer.next_token() {
    Eof => assert_true(true)
    _ => assert_true(false)
  }
}

test "lexer tokenizes keywords" {
  let input = "interface function const"
  let lexer = Lexer::new(input)
  
  match lexer.next_token() {
    Interface => assert_true(true)
    _ => assert_true(false)
  }
  match lexer.next_token() {
    Function => assert_true(true)
    _ => assert_true(false)
  }
  match lexer.next_token() {
    Const => assert_true(true)
    _ => assert_true(false)
  }
}

test "lexer tokenizes symbols" {
  let input = "{}():;"
  let lexer = Lexer::new(input)
  
  match lexer.next_token() {
    LeftBrace => assert_true(true)
    _ => assert_true(false)
  }
  match lexer.next_token() {
    RightBrace => assert_true(true)
    _ => assert_true(false)
  }
  match lexer.next_token() {
    LeftParen => assert_true(true)
    _ => assert_true(false)
  }
  match lexer.next_token() {
    RightParen => assert_true(true)
    _ => assert_true(false)
  }
  match lexer.next_token() {
    Colon => assert_true(true)
    _ => assert_true(false)
  }
  match lexer.next_token() {
    Semicolon => assert_true(true)
    _ => assert_true(false)
  }
}

test "lexer tokenizes type annotations" {
  let input = "name: string"
  let lexer = Lexer::new(input)
  
  match lexer.next_token() {
    Identifier(name) => assert_eq(name, "name")
    _ => assert_true(false)
  }
  match lexer.next_token() {
    Colon => assert_true(true)
    _ => assert_true(false)
  }
  match lexer.next_token() {
    Identifier(name) => assert_eq(name, "string")
    _ => assert_true(false)
  }
}