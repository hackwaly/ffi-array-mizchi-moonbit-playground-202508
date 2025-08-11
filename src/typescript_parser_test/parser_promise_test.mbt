
test "parse Promise<mbt.String> as TypeReference with type arg" {
  let input = "Promise<mbt.String>"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  match parser.parse_expr() {
    Some(TypeReference(name, args)) => {
      assert_eq(name, "Promise")
      assert_eq(args.length(), 1)
      match args[0] {
        @typescript_parser.Type::TypeReference(innerName, innerArgs) => {
          assert_eq(innerName, "mbt.String")
          assert_eq(innerArgs.length(), 0)
        }
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

///|
test "async function with explicit Promise return is not double-wrapped" {
  let input = "async function f(p: mbt.String): Promise<mbt.String> {}"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  match parser.parse_function_declaration() {
    Some(func) => {
      assert_eq(func.name, "f")
      assert_eq(func.params.length(), 1)
      // param type check
      match func.params[0].type_ {
        @typescript_parser.Type::TypeReference(paramName, paramArgs) => {
          assert_eq(paramName, "mbt.String")
          assert_eq(paramArgs.length(), 0)
        }
        _ => assert_true(false)
      }
      // return type must be single Promise
      match func.return_type {
        @typescript_parser.Type::TypeReference(retName, retArgs) => {
          assert_eq(retName, "Promise")
          assert_eq(retArgs.length(), 1)
          match retArgs[0] {
            @typescript_parser.Type::TypeReference(innerName, innerArgs) => {
              assert_eq(innerName, "mbt.String")
              assert_eq(innerArgs.length(), 0)
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
