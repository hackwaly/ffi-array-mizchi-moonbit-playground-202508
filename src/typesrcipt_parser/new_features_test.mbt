// Tests for new parser features

///|
test "parse rest parameter" {
  let input = "function spread(...args: any[]): void {}"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_typescript_file()
  inspect(declarations.length(), content="1")
  match declarations[0] {
    Function(func) => {
      inspect(func.name, content="spread")
      inspect(func.params.length(), content="1")
      inspect(func.params[0].rest, content="true")
      inspect(func.params[0].name, content="args")
    }
    _ => inspect(false, content="should be function")
  }
}

///|
test "parse tuple type" {
  let input = "type Point = [number, number]"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_typescript_file()
  inspect(declarations.length(), content="1")
  match declarations[0] {
    TypeAlias(type_alias) => {
      inspect(type_alias.name, content="Point")
      match type_alias.type_ {
        Tuple(types) => {
          inspect(types.length(), content="2")
          match types[0] {
            Number => assert_true(true)
            _ => assert_true(false)
          }
          match types[1] {
            Number => assert_true(true)
            _ => assert_true(false)
          }
        }
        _ => inspect(false, content="should be tuple")
      }
    }
    _ => inspect(false, content="should be type alias")
  }
}

///|
test "parse literal types" {
  let input = "type Status = \"success\" | \"error\" | \"pending\""
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_typescript_file()
  inspect(declarations.length(), content="1")
  match declarations[0] {
    TypeAlias(type_alias) => {
      inspect(type_alias.name, content="Status")
      match type_alias.type_ {
        Union(types) => {
          inspect(types.length(), content="3")
          match types[0] {
            Literal(String(s)) => inspect(s, content="success")
            _ => inspect(false, content="should be string literal")
          }
        }
        _ => inspect(false, content="should be union")
      }
    }
    _ => inspect(false, content="should be type alias")
  }
}

///|
test "parse declare function" {
  let input = "declare function external(x: number): string"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_typescript_file()
  inspect(declarations.length(), content="1")
  match declarations[0] {
    Function(func) => {
      inspect(func.name, content="external")
      inspect(func.declare, content="true")
      inspect(func.params.length(), content="1")
    }
    _ => inspect(false, content="should be function")
  }
}

///|
test "parse export default" {
  let input = "export default function main(): void {}"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_typescript_file()
  inspect(declarations.length(), content="1")
  match declarations[0] {
    Export(export_decl) =>
      match export_decl.declaration {
        Some(Function(func)) => inspect(func.name, content="main")
        _ => inspect(false, content="should be function")
      }
    _ => inspect(false, content="should be export")
  }
}

///|
test "parse class implements" {
  let input = "class MyClass implements Interface1, Interface2 {}"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_typescript_file()
  inspect(declarations.length(), content="1")
  match declarations[0] {
    Class(cls) => {
      inspect(cls.name, content="MyClass")
      inspect(cls.implements.length(), content="2")
      inspect(cls.implements[0], content="Interface1")
      inspect(cls.implements[1], content="Interface2")
    }
    _ => inspect(false, content="should be class")
  }
}

///|
test "parse optional parameter" {
  let input = "function optional(x?: string): void {}"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_typescript_file()
  inspect(declarations.length(), content="1")
  match declarations[0] {
    Function(func) => {
      inspect(func.name, content="optional")
      inspect(func.params.length(), content="1")
      inspect(func.params[0].optional, content="true")
      inspect(func.params[0].name, content="x")
    }
    _ => inspect(false, content="should be function")
  }
}
