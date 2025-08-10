test "parser parses empty object type" {
  let input = "{}"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_type() {
    Some(Object(props)) => {
      assert_eq(props.size(), 0)
    }
    _ => assert_true(false)
  }
}

test "parser parses object type with single property" {
  let input = "{ name: string }"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_type() {
    Some(Object(props)) => {
      assert_eq(props.size(), 1)
      match props.get("name") {
        Some(Type::String) => assert_true(true)
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

test "parser parses object type with multiple properties" {
  let input = "{ name: string, age: number }"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_type() {
    Some(Object(props)) => {
      assert_eq(props.size(), 2)
      match props.get("name") {
        Some(Type::String) => assert_true(true)
        _ => assert_true(false)
      }
      match props.get("age") {
        Some(Type::Number) => assert_true(true)
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

test "parser parses nested object type" {
  let input = "{ user: { name: string, age: number } }"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_type() {
    Some(Object(props)) => {
      assert_eq(props.size(), 1)
      match props.get("user") {
        Some(Object(user_props)) => {
          assert_eq(user_props.size(), 2)
          match user_props.get("name") {
            Some(Type::String) => assert_true(true)
            _ => assert_true(false)
          }
          match user_props.get("age") {
            Some(Type::Number) => assert_true(true)
            _ => assert_true(false)
          }
        }
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

test "parser parses object with array property" {
  let input = "{ items: string[] }"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_type() {
    Some(Object(props)) => {
      assert_eq(props.size(), 1)
      match props.get("items") {
        Some(Array(elem_type)) => {
          match elem_type {
            Type::String => assert_true(true)
            _ => assert_true(false)
          }
        }
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

test "parser parses JSON-like interface" {
  let input = "interface User { id: number; name: string; tags: string[]; settings: { theme: string } }"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_interface() {
    Some(iface) => {
      assert_eq(iface.name, "User")
      assert_eq(iface.members.length(), 4)
      
      // Check id property
      match iface.members[0] {
        Property(prop) => {
          assert_eq(prop.name, "id")
          match prop.type_ {
            Type::Number => assert_true(true)
            _ => assert_true(false)
          }
        }
        _ => assert_true(false)
      }
      
      // Check tags property (array)
      match iface.members[2] {
        Property(prop) => {
          assert_eq(prop.name, "tags")
          match prop.type_ {
            Array(elem_type) => {
              match elem_type {
                Type::String => assert_true(true)
                _ => assert_true(false)
              }
            }
            _ => assert_true(false)
          }
        }
        _ => assert_true(false)
      }
      
      // Check settings property (nested object)
      match iface.members[3] {
        Property(prop) => {
          assert_eq(prop.name, "settings")
          match prop.type_ {
            Object(props) => {
              assert_eq(props.size(), 1)
              match props.get("theme") {
                Some(Type::String) => assert_true(true)
                _ => assert_true(false)
              }
            }
            _ => assert_true(false)
          }
        }
        _ => assert_true(false)
      }
    }
    None => assert_true(false)
  }
}