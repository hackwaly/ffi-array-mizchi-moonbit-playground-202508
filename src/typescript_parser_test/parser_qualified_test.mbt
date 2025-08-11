test "parser parses qualified name simple" {
  let input = "mbt.Int"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  match parser.parse_expr() {
    Some(TypeReference(name, args)) => {
      assert_eq(name, "mbt.Int")
      assert_eq(args.length(), 0)
    }
    _ => assert_true(false)
  }
}

///|
test "parser parses multi-segment qualified name" {
  let input = "foo.Bar.Baz"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  match parser.parse_expr() {
    Some(TypeReference(name, args)) => {
      assert_eq(name, "foo.Bar.Baz")
      assert_eq(args.length(), 0)
    }
    _ => assert_true(false)
  }
}

///|
test "qualified name used inside object property" {
  let input = "{ t: mbt.String }"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  match parser.parse_expr() {
    Some(Object(props)) =>
      match props.get("t") {
        Some(TypeReference(name, args)) => {
          assert_eq(name, "mbt.String")
          assert_eq(args.length(), 0)
        }
        _ => assert_true(false)
      }
    _ => assert_true(false)
  }
}
