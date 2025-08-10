// Parser implementation using Pratt parsing
///|
pub struct Parser {
  lexer : Lexer
  mut current_token : Token
  mut peek_token : Token
}

///|
pub fn Parser::new(lexer : Lexer) -> Parser {
  let parser = Parser::{
    lexer,
    current_token: Token::Eof,
    peek_token: Token::Eof,
  }
  // Read two tokens to initialize current and peek
  parser.next_token()
  parser.next_token()
  parser
}

///|
fn next_token(self : Parser) -> Unit {
  self.current_token = self.peek_token
  self.peek_token = self.lexer.next_token()
}

///|
fn current_token_is(self : Parser, token : Token) -> Bool {
  self.current_token == token
}

///|
fn peek_token_is(self : Parser, token : Token) -> Bool {
  self.peek_token == token
}

///|
fn expect_peek(self : Parser, token : Token) -> Bool {
  if self.peek_token_is(token) {
    self.next_token()
    true
  } else {
    false
  }
}

// Parse a simple type

///|
pub fn parse_type(self : Parser) -> Type? {
  // ベース型の解釈
  let base_opt = match self.current_token {
    LeftParen =>
      // 関数型: (params) => return
      return self.parse_function_type()
    LeftBrace =>
      // オブジェクト型: { key: type, ... }
      return self.parse_object_type()
    Identifier(_) => {
      // QualifiedName および型引数のサポート
      let name = self.parse_qualified_name()
      let mut args : Array[Type] = []
      if self.peek_token_is(Token::LessThan) {
        self.next_token() // move to <
        let parsed = self.parse_type_arguments()
        args = parsed
      }
      // 組み込みプリミティブ名のマッピング
      match name {
        "string" => Some(Type::String)
        "number" => Some(Type::Number)
        "boolean" => Some(Type::Boolean)
        "void" => Some(Type::Void)
        "any" => Some(Type::Any)
        "unknown" => Some(Type::Unknown)
        "never" => Some(Type::Never)
        "null" => Some(Type::Null)
        "undefined" => Some(Type::Undefined)
        _ => Some(Type::TypeReference(name, args))
      }
    }
    _ => None
  }
  match base_opt {
    Some(base) => {
      // 配列サフィックス: T[]
      if self.peek_token_is(Token::LeftBracket) {
        self.next_token() // consume [
        if self.expect_peek(Token::RightBracket) {
          return Some(Type::Array(base))
        }
      }

      // ユニオン型: T | U | ...
      if self.peek_token_is(Token::Pipe) {
        let types = [base]
        while self.peek_token_is(Token::Pipe) {
          self.next_token() // consume |
          self.next_token() // move to next type start
          match self.parse_type() {
            Some(t) => types.push(t)
            None => break
          }
        }
        return Some(Type::Union(types))
      }
      Some(base)
    }
    None => None
  }
}

// Parse object type: { key: type, ... }

///|
fn parse_object_type(self : Parser) -> Type? {
  if not(self.current_token_is(Token::LeftBrace)) {
    return None
  }
  let props : Map[String, Type] = Map::new()
  self.next_token() // consume {
  while not(self.current_token_is(Token::RightBrace)) &&
        not(self.current_token_is(Token::Eof)) {
    // Parse property name
    let prop_name = match self.current_token {
      Identifier(name) => name
      _ => return None
    }

    // Expect colon
    if not(self.expect_peek(Token::Colon)) {
      return None
    }
    self.next_token() // move to type
    // Parse property type
    match self.parse_type() {
      Some(prop_type) => {
        props.set(prop_name, prop_type)
        self.next_token() // Move past the type
      }
      None => return None
    }

    // Check for comma or semicolon separator
    if self.current_token_is(Token::Comma) ||
      self.current_token_is(Token::Semicolon) {
      self.next_token() // move to next property
    } else if not(self.current_token_is(Token::RightBrace)) {
      // If not separator and not closing brace, something is wrong
      break
    }
  }
  if not(self.current_token_is(Token::RightBrace)) {
    return None
  }
  Some(Type::Object(props))
}

// Parse function type: (params) => return

///|
fn parse_function_type(self : Parser) -> Type? {
  if not(self.current_token_is(Token::LeftParen)) {
    return None
  }
  let params : Array[Parameter] = []
  self.next_token() // consume (
  while not(self.current_token_is(Token::RightParen)) &&
        not(self.current_token_is(Token::Eof)) {
    // Parse parameter
    match self.current_token {
      Identifier(param_name) => {
        if not(self.expect_peek(Token::Colon)) {
          return None
        }
        self.next_token() // move to type
        match self.parse_type() {
          Some(param_type) =>
            params.push(Parameter::{
              name: param_name,
              type_: param_type,
              optional: false,
              rest: false,
            })
          None => return None
        }
      }
      _ => return None
    }
    if self.peek_token_is(Token::Comma) {
      self.next_token()
      self.next_token()
    } else {
      break
    }
  }
  if not(self.expect_peek(Token::RightParen)) {
    return None
  }
  if not(self.expect_peek(Token::Arrow)) {
    return None
  }
  self.next_token() // move to return type
  match self.parse_type() {
    Some(return_type) =>
      Some(Type::Function(FunctionType::{ params, return_type }))
    None => None
  }
}

// Parse an interface member

///|
pub fn parse_interface_member(self : Parser) -> InterfaceMember? {
  match self.current_token {
    Identifier(name) => {
      let property_name = name
      let optional = if self.peek_token_is(Token::Question) {
        self.next_token() // consume ?
        true
      } else {
        false
      }
      if not(self.expect_peek(Token::Colon)) {
        return None
      }
      self.next_token() // Move to type
      match self.parse_type() {
        Some(typ) =>
          Some(
            InterfaceMember::Property(PropertyMember::{
              name: property_name,
              type_: typ,
              optional,
              readonly_: false,
            }),
          )
        None => None
      }
    }
    _ => None
  }
}

// Parse type alias: type Name = Type

///|
pub fn parse_type_alias(self : Parser) -> TypeAliasDeclaration? {
  if not(self.current_token_is(Token::Type)) {
    return None
  }
  self.next_token() // Move past 'type'
  let type_name = match self.current_token {
    Identifier(name) => name
    _ => return None
  }

  // Handle generic parameters if present
  self.next_token() // Move to potential < or =
  let type_params = if self.current_token_is(Token::LessThan) {
    let params = self.parse_type_parameters()
    // After parse_type_parameters, we're past >, need to check for =
    if not(self.current_token_is(Token::Equals)) {
      return None
    }
    params
  } else {
    // No generic params, current token should be =
    if not(self.current_token_is(Token::Equals)) {
      return None
    }
    []
  }
  self.next_token() // Move to the type definition
  match self.parse_type() {
    Some(typ) =>
      Some(TypeAliasDeclaration::{ name: type_name, type_params, type_: typ })
    None => None
  }
}

// Skip generic type arguments: <T, U, V>

///|
fn skip_generic_arguments(self : Parser) -> Unit {
  if not(self.current_token_is(Token::LessThan)) {
    return
  }
  self.next_token() // Move past <
  let mut depth = 1
  while depth > 0 && not(self.current_token_is(Token::Eof)) {
    match self.current_token {
      LessThan => depth = depth + 1
      GreaterThan => depth = depth - 1
      _ => ()
    }
    self.next_token()
  }
}

// Parse type parameters: <T, U, V>

///|
fn parse_type_parameters(self : Parser) -> Array[String] {
  let params : Array[String] = []

  // Caller already checked for LessThan, so just consume it
  if not(self.current_token_is(Token::LessThan)) {
    return params
  }
  self.next_token() // Move past <
  while not(self.current_token_is(Token::GreaterThan)) &&
        not(self.current_token_is(Token::Eof)) {
    match self.current_token {
      Identifier(param) => {
        params.push(param)
        self.next_token() // move to next token (comma or >)
        if self.current_token_is(Token::Comma) {
          self.next_token() // move past comma to next param
        }
      }
      _ => break
    }
  }
  if self.current_token_is(Token::GreaterThan) {
    self.next_token() // Move past >
  }
  params
}

// 追加: QualifiedName をパースする (Ident("." Ident)*)

///|
fn parse_qualified_name(self : Parser) -> String {
  let head = match self.current_token {
    Identifier(first) => first
    _ => return ""
  }
  let mut full = head
  while self.peek_token_is(Token::Dot) {
    self.next_token() // now at '.'
    self.next_token() // move to next identifier
    match self.current_token {
      Identifier(part) => full = full + "." + part
      _ => break
    }
  }
  full
}

// 追加: 型引数をパースする: "<" Type ("," Type)* ">"

///|
fn parse_type_arguments(self : Parser) -> Array[Type] {
  let args : Array[Type] = []
  if not(self.current_token_is(Token::LessThan)) {
    return args
  }
  // "<" を消費して最初の型へ
  self.next_token()
  while not(self.current_token_is(Token::Eof)) {
    match self.parse_type() {
      Some(t) => args.push(t)
      None => break
    }

    // 区切りのカンマ
    if self.peek_token_is(Token::Comma) {
      self.next_token() // to ","
      self.next_token() // to next type start
      continue
    }

    // 終了の ">"
    if self.peek_token_is(Token::GreaterThan) {
      self.next_token() // move to ">"
      break
    }

    // 念のためのブレーク条件
    if self.current_token_is(Token::GreaterThan) {
      break
    }
  }
  args
}

// Parse interface declaration

///|
pub fn parse_interface(self : Parser) -> InterfaceDeclaration? {
  if not(self.current_token_is(Token::Interface)) {
    return None
  }
  self.next_token() // Move to interface name
  let interface_name = match self.current_token {
    Identifier(name) => name
    _ => return None
  }

  // Handle generic parameters if present
  self.next_token() // Move to potential < or {
  let type_params = if self.current_token_is(Token::LessThan) {
    let params = self.parse_type_parameters()
    // After parse_type_parameters, we're past >, need to check for {
    if not(self.current_token_is(Token::LeftBrace)) {
      return None
    }
    params
  } else {
    // No generic params, current token should be {
    if not(self.current_token_is(Token::LeftBrace)) {
      return None
    }
    []
  }
  let members : Array[InterfaceMember] = []
  self.next_token() // Move past {
  while not(self.current_token_is(Token::RightBrace)) &&
        not(self.current_token_is(Token::Eof)) {
    match self.parse_interface_member() {
      Some(m) => members.push(m)
      None => break
    }

    // Skip optional semicolon
    if self.peek_token_is(Token::Semicolon) {
      self.next_token()
    }
    self.next_token()
  }
  Some(InterfaceDeclaration::{
    name: interface_name,
    type_params,
    extends: [],
    members,
  })
}

// Parse function declaration

///|
pub fn parse_function_declaration(self : Parser) -> FunctionDeclaration? {
  // async キーワードをチェック
  let is_async = if self.current_token_is(Token::Async) {
    self.next_token()
    true
  } else {
    false
  }
  if not(self.current_token_is(Token::Function)) {
    return None
  }
  self.next_token() // Move to function name
  let func_name = match self.current_token {
    Identifier(name) => name
    _ => return None
  }

  // ジェネリック型パラメータをスキップ
  if self.peek_token_is(Token::LessThan) {
    self.skip_generic_params()
  }
  if not(self.expect_peek(Token::LeftParen)) {
    return None
  }
  // Now current_token is LeftParen after expect_peek

  // Parse parameters  
  let params = self.parse_function_params()

  // Ensure we're past the closing paren
  if not(self.current_token_is(Token::RightParen)) {
    return None
  }
  self.next_token() // Move past )

  // Parse return type if present
  let return_type = if self.current_token_is(Token::Colon) {
    self.next_token() // Move past :
    match self.parse_type() {
      Some(typ) =>
        if is_async {
          // 既に Promise<T> なら再ラップしない
          match typ {
            TypeReference(name, inner_args) =>
              if name == "Promise" && inner_args.length() == 1 {
                typ
              } else {
                Type::TypeReference("Promise", [typ])
              }
            _ => Type::TypeReference("Promise", [typ])
          }
        } else {
          typ
        }
      None => Type::Void
    }
  } else {
    // 現行仕様に従い、戻り型未指定時は Void のまま
    Type::Void
  }

  // 関数本体をスキップ
  self.skip_function_body()
  Some(FunctionDeclaration::{
    name: func_name,
    params,
    return_type,
    declare: false,
  })
}

// 関数本体をスキップする

///|
fn skip_function_body(self : Parser) -> Unit {
  if self.peek_token_is(Token::LeftBrace) {
    self.next_token() // Move to {
    self.skip_block()
  }
}

// ブロック（{}）をスキップする

///|
fn skip_block(self : Parser) -> Unit {
  if not(self.current_token_is(Token::LeftBrace)) {
    return
  }
  let mut brace_count = 1
  self.next_token() // Move past opening {
  while brace_count > 0 && not(self.current_token_is(Token::Eof)) {
    match self.current_token {
      LeftBrace => brace_count += 1
      RightBrace => {
        brace_count -= 1
        if brace_count == 0 {
          self.next_token() // Move past closing }
          return
        }
      }
      // 文字列リテラル内のブレースはカウントしない
      StringLiteral(_) => ()
      _ => ()
    }
    self.next_token()
  }
}

// ジェネリック型パラメータをスキップする

///|
fn skip_generic_params(self : Parser) -> Unit {
  if not(self.peek_token_is(Token::LessThan)) {
    return
  }
  self.next_token() // Move to <
  let mut angle_count = 1
  self.next_token()
  while angle_count > 0 && not(self.current_token_is(Token::Eof)) {
    match self.current_token {
      LessThan => angle_count += 1
      GreaterThan => {
        angle_count -= 1
        if angle_count == 0 {
          self.next_token() // Move past >
          return
        }
      }
      _ => ()
    }
    self.next_token()
  }
}

// Parse function parameters

///|
fn parse_function_params(self : Parser) -> Array[Parameter] {
  let params : Array[Parameter] = []
  // Expect to be at ( when called, next_token to move past it
  if not(self.current_token_is(Token::LeftParen)) {
    return params
  }
  self.next_token() // Move past (
  while not(self.current_token_is(Token::RightParen)) &&
        not(self.current_token_is(Token::Eof)) {
    match self.current_token {
      Identifier(param_name) => {
        // Check for optional parameter
        let optional = if self.peek_token_is(Token::Question) {
          self.next_token() // consume ?
          true
        } else {
          false
        }
        if not(self.expect_peek(Token::Colon)) {
          break
        }
        self.next_token() // move to type
        match self.parse_type() {
          Some(param_type) => {
            params.push(Parameter::{
              name: param_name,
              type_: param_type,
              optional,
              rest: false,
            })
            self.next_token() // Move past the type
          }
          None => break
        }
      }
      _ => break
    }

    // Check for comma separator
    if self.current_token_is(Token::Comma) {
      self.next_token() // move to next parameter
    } else if not(self.current_token_is(Token::RightParen)) {
      // If not comma and not ), something is wrong
      break
    }
  }

  // Don't move past ) here, let the caller handle it
  params
}

// Parse class declaration

///|
pub fn parse_class(self : Parser) -> ClassDeclaration? {
  if not(self.current_token_is(Token::Class)) {
    return None
  }
  self.next_token() // Move to class name
  let class_name = match self.current_token {
    Identifier(name) => name
    _ => return None
  }

  // Handle generic parameters if present
  self.next_token() // Move to potential < or extends/implements/{
  let type_params = if self.current_token_is(Token::LessThan) {
    let params = self.parse_type_parameters()
    params
  } else {
    []
  }

  // Check for extends clause
  let extends = if self.current_token_is(Token::Extends) {
    self.next_token() // Move past extends
    match self.current_token {
      Identifier(base) => {
        self.next_token() // Move past base class name
        // Skip generic type arguments if present
        if self.current_token_is(Token::LessThan) {
          self.skip_generic_arguments()
        }
        Some(base)
      }
      _ => None
    }
  } else {
    None
  }

  // Parse class body
  if not(self.current_token_is(Token::LeftBrace)) {
    return None
  }
  let members : Array[ClassMember] = []
  self.next_token() // Move past {
  while not(self.current_token_is(Token::RightBrace)) &&
        not(self.current_token_is(Token::Eof)) {
    match self.parse_class_member() {
      Some(class_mem) => members.push(class_mem)
      None => break
    }

    // Skip optional semicolon
    if self.current_token_is(Token::Semicolon) {
      self.next_token()
    } else if not(self.current_token_is(Token::RightBrace)) {
      self.next_token()
    }
  }
  Some(ClassDeclaration::{
    name: class_name,
    type_params,
    extends,
    implements: [],
    members,
    declare: false,
  })
}

// Parse class member

///|
fn parse_class_member(self : Parser) -> ClassMember? {
  // Check for visibility modifier
  let visibility = match self.current_token {
    Public => {
      self.next_token()
      Visibility::Public
    }
    Private => {
      self.next_token()
      Visibility::Private
    }
    Protected => {
      self.next_token()
      Visibility::Protected
    }
    _ => Visibility::Public
  }

  // Check for static modifier
  let is_static_member = if self.current_token_is(Token::Static) {
    self.next_token()
    true
  } else {
    false
  }

  // Check for readonly modifier
  let is_readonly = if self.current_token_is(Token::Readonly) {
    self.next_token()
    true
  } else {
    false
  }

  // Check for constructor
  if self.current_token_is(Token::Constructor) {
    self.next_token() // Move past constructor
    if not(self.current_token_is(Token::LeftParen)) {
      return None
    }
    let params = self.parse_function_params()

    // Move past closing paren if present
    if self.current_token_is(Token::RightParen) {
      self.next_token()
    }
    return Some(
      ClassMember::ClassConstructor(ClassConstructorMember::{
        params,
        visibility,
      }),
    )
  }

  // Parse property or method
  match self.current_token {
    Identifier(name) => {
      let member_name = name

      // Check if it's a method (has parentheses)
      if self.peek_token_is(Token::LeftParen) {
        self.next_token() // Move to (
        let params = self.parse_function_params()

        // Move past closing paren if present
        if self.current_token_is(Token::RightParen) {
          self.next_token()
        }

        // Parse return type if present
        let return_type = if self.current_token_is(Token::Colon) {
          self.next_token() // Move past :
          match self.parse_type() {
            Some(typ) => {
              self.next_token() // Move past the type
              typ
            }
            None => Type::Void
          }
        } else {
          Type::Void
        }
        Some(
          ClassMember::ClassMethod(ClassMethodMember::{
            name: member_name,
            params,
            return_type,
            visibility,
            is_static: is_static_member,
          }),
        )
      } else {
        // It's a property
        let is_optional = if self.peek_token_is(Token::Question) {
          self.next_token() // consume ?
          true
        } else {
          false
        }
        if not(self.expect_peek(Token::Colon)) {
          return None
        }
        self.next_token() // move to type
        match self.parse_type() {
          Some(prop_type) => {
            self.next_token() // Move past the type
            Some(
              ClassMember::ClassProperty(ClassPropertyMember::{
                name: member_name,
                type_: prop_type,
                visibility,
                is_static: is_static_member,
                readonly_: is_readonly,
                optional: is_optional,
              }),
            )
          }
          None => None
        }
      }
    }
    _ => None
  }
}

// Parse top-level declaration

///|
pub fn parse_declaration(self : Parser) -> Declaration? {
  match self.current_token {
    Interface =>
      self.parse_interface().map(fn(iface) { Declaration::Interface(iface) })
    Function | Async =>
      self
      .parse_function_declaration()
      .map(fn(func) { Declaration::Function(func) })
    Class => self.parse_class().map(fn(cls) { Declaration::Class(cls) })
    Type =>
      self.parse_type_alias().map(fn(alias) { Declaration::TypeAlias(alias) })
    Const | Let | Var => self.parse_variable_declaration()
    Export => self.parse_export_declaration()
    Import => self.parse_import_declaration()
    _ => None
  }
}

// Parse export declaration

///|
fn parse_export_declaration(self : Parser) -> Declaration? {
  if not(self.current_token_is(Token::Export)) {
    return None
  }
  self.next_token() // Move past export

  // Check for named exports: export { a, b as c }
  if self.current_token_is(Token::LeftBrace) {
    return self.parse_named_exports()
  }

  // Check for export * from
  if self.current_token_is(Token::Star) {
    self.next_token() // Move past *
    if self.current_token_is(Token::From) {
      self.next_token() // Move past from
      match self.current_token {
        StringLiteral(source) =>
          return Some(
            Declaration::Export(ExportDeclaration::{
              declaration: None,
              named_exports: [],
              from: Some(source),
            }),
          )
        _ => return None
      }
    }
    return None
  }

  // Regular export declaration
  match self.parse_declaration() {
    Some(decl) =>
      Some(
        Declaration::Export(ExportDeclaration::{
          declaration: Some(decl),
          named_exports: [],
          from: None,
        }),
      )
    None => None
  }
}

// Parse named exports: export { a, b as c } or export { a, b } from 'module'

///|
fn parse_named_exports(self : Parser) -> Declaration? {
  if not(self.current_token_is(Token::LeftBrace)) {
    return None
  }
  self.next_token() // Move past {
  let exports : Array[ExportSpecifier] = []
  while not(self.current_token_is(Token::RightBrace)) &&
        not(self.current_token_is(Token::Eof)) {
    match self.current_token {
      Identifier(name) => {
        let local_name = name
        self.next_token()
        let exported = if self.current_token_is(Token::As) {
          self.next_token() // Move past as
          match self.current_token {
            Identifier(alias) => {
              self.next_token()
              Some(alias)
            }
            _ => None
          }
        } else {
          None
        }
        exports.push(ExportSpecifier::{ local_name, exported })
        if self.current_token_is(Token::Comma) {
          self.next_token() // Move past comma
        }
      }
      _ => break
    }
  }
  if not(self.current_token_is(Token::RightBrace)) {
    return None
  }
  self.next_token() // Move past }

  // Check for 'from' clause
  let from = if self.current_token_is(Token::From) {
    self.next_token() // Move past from
    match self.current_token {
      StringLiteral(source) => Some(source)
      _ => None
    }
  } else {
    None
  }
  Some(
    Declaration::Export(ExportDeclaration::{
      declaration: None,
      named_exports: exports,
      from,
    }),
  )
}

// Parse import declaration

///|
fn parse_import_declaration(self : Parser) -> Declaration? {
  if not(self.current_token_is(Token::Import)) {
    return None
  }
  self.next_token() // Move past import
  let specifiers : Array[ImportSpecifier] = []

  // Check for import type (TypeScript)
  let is_type_import = if self.current_token_is(Token::Type) {
    self.next_token()
    true
  } else {
    false
  }

  // Check import type
  if self.current_token_is(Token::LeftBrace) {
    // Named imports: import { foo, bar as baz } from 'module'
    self.parse_named_imports(specifiers)
  } else if self.current_token_is(Token::Star) {
    // Namespace import: import * as foo from 'module'
    self.next_token() // Move past *
    if self.current_token_is(Token::As) {
      self.next_token() // Move past as
      match self.current_token {
        Identifier(name) => {
          specifiers.push(ImportSpecifier::Namespace(name))
          self.next_token()
        }
        _ => return None
      }
    }
  } else {
    // Default import: import foo from 'module'
    match self.current_token {
      Identifier(name) => {
        specifiers.push(ImportSpecifier::Default(name))
        self.next_token()

        // Check for additional named imports: import foo, { bar } from 'module'
        if self.current_token_is(Token::Comma) {
          self.next_token()
          if self.current_token_is(Token::LeftBrace) {
            self.parse_named_imports(specifiers)
          }
        }
      }
      _ => ()
    }
  }

  // Expect 'from' keyword
  if not(self.current_token_is(Token::From)) {
    return None
  }
  self.next_token() // Move past from

  // Get the module source
  let from = match self.current_token {
    StringLiteral(source) => source
    _ => return None
  }
  Some(Declaration::Import(ImportDeclaration::{ specifiers, from }))
}

// Helper to parse named imports

///|
fn parse_named_imports(
  self : Parser,
  specifiers : Array[ImportSpecifier],
) -> Unit {
  if not(self.current_token_is(Token::LeftBrace)) {
    return
  }
  self.next_token() // Move past {
  while not(self.current_token_is(Token::RightBrace)) &&
        not(self.current_token_is(Token::Eof)) {
    match self.current_token {
      Identifier(name) => {
        let local_name = name
        self.next_token()
        let imported = if self.current_token_is(Token::As) {
          self.next_token() // Move past as
          match self.current_token {
            Identifier(alias) => {
              self.next_token()
              Some(alias)
            }
            _ => None
          }
        } else {
          None
        }
        specifiers.push(ImportSpecifier::Named(local_name, imported))
        if self.current_token_is(Token::Comma) {
          self.next_token() // Move past comma
        }
      }
      _ => break
    }
  }
  if self.current_token_is(Token::RightBrace) {
    self.next_token() // Move past }
  }
}

// 変数宣言をパース（型情報のみ抽出）

///|
fn parse_variable_declaration(self : Parser) -> Declaration? {
  let _kind = match self.current_token {
    Const => "const"
    Let => "let"
    Var => "var"
    _ => return None
  }
  self.next_token() // Move past const/let/var
  let var_name = match self.current_token {
    Identifier(name) => name
    _ => return None
  }

  // 型注釈があればパース
  let var_type = if self.expect_peek(Token::Colon) {
    self.next_token() // Move to type
    match self.parse_type() {
      Some(typ) => {
        self.next_token() // Move past type
        typ
      }
      None => Type::Any
    }
  } else {
    Type::Any
  }

  // 初期化式をスキップ
  if self.current_token_is(Token::Equals) {
    self.skip_expression()
  }

  // セミコロンをスキップ
  if self.current_token_is(Token::Semicolon) {
    self.next_token()
  }

  // 簡易的に関数宣言として扱う（変数に代入された関数の場合）
  Some(
    Declaration::Function(FunctionDeclaration::{
      name: var_name,
      params: [],
      return_type: var_type,
      declare: false,
    }),
  )
}

// 式をスキップする

///|
fn skip_expression(self : Parser) -> Unit {
  self.next_token() // Move past =
  let mut depth = 0
  while not(self.current_token_is(Token::Eof)) {
    match self.current_token {
      LeftParen | LeftBrace | LeftBracket => depth += 1
      RightParen | RightBrace | RightBracket =>
        if depth > 0 {
          depth -= 1
        } else {
          return
        }
      Semicolon | Comma => if depth == 0 { return }
      _ => ()
    }
    self.next_token()
  }
}

// TypeScriptファイル全体をパース

///|
pub fn parse_typescript_file(self : Parser) -> Array[Declaration] {
  let declarations : Array[Declaration] = []
  while not(self.current_token_is(Token::Eof)) {
    match self.parse_declaration() {
      Some(decl) => declarations.push(decl)
      None =>
        // パースできなかった場合は次のトークンへ
        self.next_token()
    }
  }
  declarations
}
