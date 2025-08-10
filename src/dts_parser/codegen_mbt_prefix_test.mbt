// Tests for mbt.* prefix mapping in type_to_moonbit

///|
test "type_to_moonbit maps mbt.String -> String" {
  let lexer = Lexer::new("mbt.String")
  let parser = Parser::new(lexer)
  match parser.parse_type() {
    Some(t) => assert_eq(type_to_moonbit(t), "String")
    None => assert_true(false)
  }
}

///|
test "type_to_moonbit maps mbt.Int -> Int" {
  let lexer = Lexer::new("mbt.Int")
  let parser = Parser::new(lexer)
  match parser.parse_type() {
    Some(t) => assert_eq(type_to_moonbit(t), "Int")
    None => assert_true(false)
  }
}

///|
test "type_to_moonbit maps mbt.Float -> Double" {
  let lexer = Lexer::new("mbt.Float")
  let parser = Parser::new(lexer)
  match parser.parse_type() {
    Some(t) => assert_eq(type_to_moonbit(t), "Double")
    None => assert_true(false)
  }
}

///|
test "type_to_moonbit maps Promise<mbt.String> -> Promise[String]" {
  let lexer = Lexer::new("Promise<mbt.String>")
  let parser = Parser::new(lexer)
  match parser.parse_type() {
    Some(t) => assert_eq(type_to_moonbit(t), "Promise[String]")
    None => assert_true(false)
  }
}

///|
test "type_to_moonbit falls back mbt.Custom -> Custom" {
  let lexer = Lexer::new("mbt.Custom")
  let parser = Parser::new(lexer)
  match parser.parse_type() {
    Some(t) => assert_eq(type_to_moonbit(t), "Custom")
    None => assert_true(false)
  }
}

///|
test "type_to_moonbit maps mbt.Void -> Unit" {
  let lexer = Lexer::new("mbt.Void")
  let parser = Parser::new(lexer)
  match parser.parse_type() {
    Some(t) => assert_eq(type_to_moonbit(t), "Unit")
    None => assert_true(false)
  }
}
