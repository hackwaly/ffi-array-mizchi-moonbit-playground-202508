// TypeScript subset validator tests - シンプルな実装から開始

///|
test "parse and validate primitive types" {
  let input = "declare const x: string; declare const y: number; declare const z: boolean;"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)

  // stringをパース
  let decl1 = parser.parse_declaration()
  match decl1 {
    Some(Variable(v)) => {
      inspect(v.name, content="x")
      match v.type_ {
        String => inspect(true, content="true")
        _ => inspect(false, content="true")
      }
    }
    _ => inspect(false, content="true")
  }
}

///|
test "parse array type" {
  let input = "declare const arr: string[];"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let result = parser.parse_declaration()
  match result {
    Some(Variable(v)) => {
      inspect(v.name, content="arr")
      match v.type_ {
        Array(_) => inspect(true, content="true")
        _ => inspect(false, content="true")
      }
    }
    _ => inspect(false, content="true")
  }
}

///|
test "parse promise type" {
  let input = "declare function fetchData(): Promise<string>;"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let result = parser.parse_declaration()
  match result {
    Some(Function(f)) => {
      inspect(f.name, content="fetchData")
      match f.return_type {
        TypeReference(name, _) => inspect(name, content="Promise")
        _ => inspect(false, content="true")
      }
    }
    _ => inspect(false, content="true")
  }
}

///|
test "parse union type" {
  let input = "declare const nullable: string | null;"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let result = parser.parse_declaration()
  match result {
    Some(Variable(v)) => {
      inspect(v.name, content="nullable")
      match v.type_ {
        Union(types) => inspect(types.length(), content="2")
        _ => inspect(false, content="true")
      }
    }
    _ => inspect(false, content="true")
  }
}

///|
test "parse interface declaration" {
  let input = "interface Point { x: number; y: number; }"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let result = parser.parse_declaration()
  match result {
    Some(Interface(iface)) => {
      inspect(iface.name, content="Point")
      inspect(iface.members.length(), content="2")
    }
    _ => inspect(false, content="true")
  }
}

///|
test "parse type alias" {
  let input = "type StringOrNumber = string | number;"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let result = parser.parse_declaration()
  match result {
    Some(TypeAlias(alias_)) => {
      inspect(alias_.name, content="StringOrNumber")
      match alias_.type_ {
        Union(types) => inspect(types.length(), content="2")
        _ => inspect(false, content="true")
      }
    }
    _ => inspect(false, content="true")
  }
}

///|
test "parse class declaration" {
  let input = "class User { name: string; age: number; }"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let result = parser.parse_declaration()
  match result {
    Some(Class(cls)) => {
      inspect(cls.name, content="User")
      inspect(cls.members.length(), content="2")
    }
    _ => inspect(false, content="true")
  }
}

///|
test "parse optional parameters" {
  let input = "function greet(name: string, title?: string): void {}"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let result = parser.parse_declaration()
  match result {
    Some(Function(func)) => {
      inspect(func.params[0].optional, content="false")
      inspect(func.params[1].optional, content="true")
    }
    _ => inspect(false, content="true")
  }
}

///|
test "parse rest parameters" {
  let input = "function sum(...numbers: number[]): number {}"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let result = parser.parse_declaration()
  match result {
    Some(Function(func)) => {
      inspect(func.params[0].rest, content="true")
      match func.params[0].type_ {
        Array(_) => inspect(true, content="true")
        _ => inspect(false, content="true")
      }
    }
    _ => inspect(false, content="true")
  }
}

///|
test "parse tuple type" {
  let input = "declare const tuple: [string, number];"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let result = parser.parse_declaration()
  match result {
    Some(Variable(v)) =>
      match v.type_ {
        Tuple(types) => inspect(types.length(), content="2")
        _ => inspect(false, content="true")
      }
    _ => inspect(false, content="true")
  }
}

///|
test "parse literal types" {
  let input = "declare const literal: \"hello\";"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let result = parser.parse_declaration()
  match result {
    Some(Variable(v)) =>
      match v.type_ {
        Literal(_) => inspect(true, content="true")
        _ => inspect(false, content="true")
      }
    _ => inspect(false, content="true")
  }
}

///|
test "parse readonly modifier" {
  let input = "interface Config { readonly apiKey: string; }"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let result = parser.parse_declaration()
  match result {
    Some(Interface(iface)) =>
      match iface.members[0] {
        Property(prop) => inspect(prop.readonly_, content="true")
        _ => inspect(false, content="true")
      }
    _ => inspect(false, content="true")
  }
}
