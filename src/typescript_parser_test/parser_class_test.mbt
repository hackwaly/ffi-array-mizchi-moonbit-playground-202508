test "parser parses empty class" {
  let input = "class MyClass {}"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_class() {
    Some(cls) => {
      assert_eq(cls.name, "MyClass")
      assert_eq(cls.members.length(), 0)
    }
    None => assert_true(false)
  }
}

test "parser parses class with property" {
  let input = "class Person { name: string }"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_class() {
    Some(cls) => {
      assert_eq(cls.name, "Person")
      assert_eq(cls.members.length(), 1)
      match cls.members[0] {
        ClassProperty(prop) => {
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

test "parser parses class with method" {
  let input = "class Calculator { add(a: number, b: number): number }"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_class() {
    Some(cls) => {
      assert_eq(cls.name, "Calculator")
      assert_eq(cls.members.length(), 1)
      match cls.members[0] {
        ClassMethod(m) => {
          assert_eq(m.name, "add")
          assert_eq(m.params.length(), 2)
          match m.return_type {
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

test "parser parses class with constructor" {
  let input = "class Person { constructor(name: string) }"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_class() {
    Some(cls) => {
      assert_eq(cls.name, "Person")
      assert_eq(cls.members.length(), 1)
      match cls.members[0] {
        ClassConstructor(ctor) => {
          assert_eq(ctor.params.length(), 1)
          assert_eq(ctor.params[0].name, "name")
          match ctor.params[0].type_ {
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

test "parser parses class with extends" {
  let input = "class Student extends Person {}"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_class() {
    Some(cls) => {
      assert_eq(cls.name, "Student")
      match cls.extends {
        Some(base) => assert_eq(base, "Person")
        None => assert_true(false)
      }
    }
    None => assert_true(false)
  }
}

test "parser parses class with public/private modifiers" {
  let input = "class Account { private balance: number; public getName(): string }"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  
  match parser.parse_class() {
    Some(cls) => {
      assert_eq(cls.name, "Account")
      assert_eq(cls.members.length(), 2)
      
      // Check private property
      match cls.members[0] {
        ClassProperty(prop) => {
          assert_eq(prop.name, "balance")
          match prop.visibility {
            Private => assert_true(true)
            _ => assert_true(false)
          }
        }
        _ => assert_true(false)
      }
      
      // Check public method
      match cls.members[1] {
        ClassMethod(m) => {
          assert_eq(m.name, "getName")
          match m.visibility {
            Public => assert_true(true)
            _ => assert_true(false)
          }
        }
        _ => assert_true(false)
      }
    }
    None => assert_true(false)
  }
}