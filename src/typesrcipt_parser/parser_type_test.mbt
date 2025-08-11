test "parser parses array type" {
  let input = "string[]"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_type() {
    Some(Array(element_type)) => {
      match element_type {
        Type::String => assert_true(true)
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

test "parser parses union type" {
  let input = "string | number"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_type() {
    Some(Union(types)) => {
      assert_eq(types.length(), 2)
      match types[0] {
        Type::String => assert_true(true)
        _ => assert_true(false)
      }
      match types[1] {
        Type::Number => assert_true(true)
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

test "parser parses optional property" {
  let input = "name?: string"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_interface_member() {
    Some(Property(prop)) => {
      assert_eq(prop.name, "name")
      assert_eq(prop.optional, true)
      match prop.type_ {
        Type::String => assert_true(true)
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

test "parser parses function type" {
  let input = "(x: number) => string"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_type() {
    Some(Function(func)) => {
      assert_eq(func.params.length(), 1)
      assert_eq(func.params[0].name, "x")
      match func.params[0].type_ {
        Type::Number => assert_true(true)
        _ => assert_true(false)
      }
      match func.return_type {
        Type::String => assert_true(true)
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}