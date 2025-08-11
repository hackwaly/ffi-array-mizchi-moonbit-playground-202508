///|
test "parse import type namespace" {
  let input = "import type * as mbt from './x.d.ts'"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse_declarations()
  inspect(declarations.length(), content="1")
  match declarations[0] {
    Import(import_decl) => {
      inspect(import_decl.from, content="./x.d.ts")
      inspect(import_decl.specifiers.length(), content="1")
      match import_decl.specifiers[0] {
        Namespace(name) => inspect(name, content="mbt")
        _ => inspect(false, content="should be namespace import")
      }
    }
    _ => inspect(false, content="should be import")
  }
}
