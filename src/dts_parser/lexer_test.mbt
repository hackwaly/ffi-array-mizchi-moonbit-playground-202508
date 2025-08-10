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