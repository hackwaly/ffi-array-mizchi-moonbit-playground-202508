test "parser parses simple type" {
  let input = "string"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_expr() {
    Some(@typescript_parser.Type::String) => assert_true(true)
    _ => assert_true(false)
  }
}

test "parser parses type reference" {
  let input = "MyType"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_expr() {
    Some(@typescript_parser.Type::TypeReference(name, _)) => assert_eq(name, "MyType")
    _ => assert_true(false)
  }
}

test "parser parses interface property" {
  let input = "name: string"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_interface_member() {
    Some(Property(prop)) => {
      assert_eq(prop.name, "name")
      match prop.type_ {
        @typescript_parser.Type::String => assert_true(true)
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

test "parser parses simple interface" {
  let input = "interface User { name: string }"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_interface() {
    Some(iface) => {
      assert_eq(iface.name, "User")
      assert_eq(iface.members.length(), 1)
      match iface.members[0] {
        Property(prop) => {
          assert_eq(prop.name, "name")
          match prop.type_ {
            @typescript_parser.Type::String => assert_true(true)
            _ => assert_true(false)
          }
        }
        _ => assert_true(false)
      }
    }
    None => assert_true(false)
  }
}

test "parser parses interface with multiple properties" {
  let input = "interface Person { name: string; age: number }"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_interface() {
    Some(iface) => {
      assert_eq(iface.name, "Person")
      assert_eq(iface.members.length(), 2)
      
      // Check first property
      match iface.members[0] {
        Property(prop) => {
          assert_eq(prop.name, "name")
          match prop.type_ {
            @typescript_parser.Type::String => assert_true(true)
            _ => assert_true(false)
          }
        }
        _ => assert_true(false)
      }
      
      // Check second property
      match iface.members[1] {
        Property(prop) => {
          assert_eq(prop.name, "age")
          match prop.type_ {
            @typescript_parser.Type::Number => assert_true(true)
            _ => assert_true(false)
          }
        }
        _ => assert_true(false)
      }
    }
    None => assert_true(false)
  }
}