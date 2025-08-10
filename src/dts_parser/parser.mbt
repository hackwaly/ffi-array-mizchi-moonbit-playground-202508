// Parser implementation using Pratt parsing
pub struct Parser {
  lexer : Lexer
  mut current_token : Token
  mut peek_token : Token
}

pub fn Parser::new(lexer : Lexer) -> Parser {
  let parser = Parser::{
    lexer,
    current_token: Token::Eof,
    peek_token: Token::Eof
  }
  // Read two tokens to initialize current and peek
  parser.next_token()
  parser.next_token()
  parser
}

fn next_token(self : Parser) -> Unit {
  self.current_token = self.peek_token
  self.peek_token = self.lexer.next_token()
}

fn current_token_is(self : Parser, token : Token) -> Bool {
  self.current_token == token
}

fn peek_token_is(self : Parser, token : Token) -> Bool {
  self.peek_token == token
}

fn expect_peek(self : Parser, token : Token) -> Bool {
  if self.peek_token_is(token) {
    self.next_token()
    true
  } else {
    false
  }
}

// Parse a simple type
pub fn parse_type(self : Parser) -> Option[Type] {
  let base_type = match self.current_token {
    LeftParen => {
      // Function type: (params) => return
      return self.parse_function_type()
    }
    LeftBrace => {
      // Object type: { key: type, ... }
      return self.parse_object_type()
    }
    Identifier(name) => {
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
        _ => Some(Type::TypeReference(name, []))
      }
    }
    _ => None
  }
  
  match base_type {
    Some(typ) => {
      // Check for array notation
      if self.peek_token_is(Token::LeftBracket) {
        self.next_token() // consume [
        if self.expect_peek(Token::RightBracket) {
          return Some(Type::Array(typ))
        }
      }
      
      // Check for union type
      if self.peek_token_is(Token::Pipe) {
        let types = [typ]
        while self.peek_token_is(Token::Pipe) {
          self.next_token() // consume |
          self.next_token() // move to next type
          match self.parse_type() {
            Some(t) => types.push(t)
            None => break
          }
        }
        return Some(Type::Union(types))
      }
      
      Some(typ)
    }
    None => None
  }
}

// Parse object type: { key: type, ... }
fn parse_object_type(self : Parser) -> Option[Type] {
  if not(self.current_token_is(Token::LeftBrace)) {
    return None
  }
  
  let props : Map[String, Type] = Map::new()
  self.next_token() // consume {
  
  while not(self.current_token_is(Token::RightBrace)) && not(self.current_token_is(Token::Eof)) {
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
    if self.current_token_is(Token::Comma) || self.current_token_is(Token::Semicolon) {
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
fn parse_function_type(self : Parser) -> Option[Type] {
  if not(self.current_token_is(Token::LeftParen)) {
    return None
  }
  
  let params : Array[Parameter] = []
  self.next_token() // consume (
  
  while not(self.current_token_is(Token::RightParen)) && not(self.current_token_is(Token::Eof)) {
    // Parse parameter
    match self.current_token {
      Identifier(param_name) => {
        if not(self.expect_peek(Token::Colon)) {
          return None
        }
        self.next_token() // move to type
        match self.parse_type() {
          Some(param_type) => {
            params.push(Parameter::{
              name: param_name,
              type_: param_type,
              optional: false,
              rest: false
            })
          }
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
    Some(return_type) => {
      Some(Type::Function(FunctionType::{
        params,
        return_type
      }))
    }
    None => None
  }
}

// Parse an interface member
pub fn parse_interface_member(self : Parser) -> Option[InterfaceMember] {
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
        Some(typ) => {
          Some(InterfaceMember::Property(PropertyMember::{
            name: property_name,
            type_: typ,
            optional,
            readonly_: false
          }))
        }
        None => None
      }
    }
    _ => None
  }
}

// Parse interface declaration
pub fn parse_interface(self : Parser) -> Option[InterfaceDeclaration] {
  if not(self.current_token_is(Token::Interface)) {
    return None
  }
  
  self.next_token() // Move to interface name
  let interface_name = match self.current_token {
    Identifier(name) => name
    _ => return None
  }
  
  if not(self.expect_peek(Token::LeftBrace)) {
    return None
  }
  
  let members : Array[InterfaceMember] = []
  self.next_token() // Move past {
  
  while not(self.current_token_is(Token::RightBrace)) && not(self.current_token_is(Token::Eof)) {
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
    type_params: [],
    extends: [],
    members
  })
}

// Parse function declaration
pub fn parse_function_declaration(self : Parser) -> Option[FunctionDeclaration] {
  if not(self.current_token_is(Token::Function)) {
    return None
  }
  
  self.next_token() // Move to function name
  let func_name = match self.current_token {
    Identifier(name) => name
    _ => return None
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
      Some(typ) => typ
      None => Type::Void
    }
  } else {
    Type::Void // Default to void if no return type specified
  }
  
  Some(FunctionDeclaration::{
    name: func_name,
    params,
    return_type,
    declare: false
  })
}

// Parse function parameters
fn parse_function_params(self : Parser) -> Array[Parameter] {
  let params : Array[Parameter] = []
  // Expect to be at ( when called, next_token to move past it
  if not(self.current_token_is(Token::LeftParen)) {
    return params
  }
  self.next_token() // Move past (
  
  while not(self.current_token_is(Token::RightParen)) && not(self.current_token_is(Token::Eof)) {
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
              rest: false
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
pub fn parse_class(self : Parser) -> Option[ClassDeclaration] {
  if not(self.current_token_is(Token::Class)) {
    return None
  }
  
  self.next_token() // Move to class name
  let class_name = match self.current_token {
    Identifier(name) => name
    _ => return None
  }
  
  self.next_token() // Move past class name
  
  // Check for extends clause
  let extends = if self.current_token_is(Token::Extends) {
    self.next_token() // Move past extends
    match self.current_token {
      Identifier(base) => {
        self.next_token() // Move past base class name
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
  
  while not(self.current_token_is(Token::RightBrace)) && not(self.current_token_is(Token::Eof)) {
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
    type_params: [],
    extends,
    implements: [],
    members,
    declare: false
  })
}

// Parse class member
fn parse_class_member(self : Parser) -> Option[ClassMember] {
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
    
    return Some(ClassMember::ClassConstructor(ClassConstructorMember::{
      params,
      visibility
    }))
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
        
        Some(ClassMember::ClassMethod(ClassMethodMember::{
          name: member_name,
          params,
          return_type,
          visibility,
          is_static: is_static_member
        }))
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
            Some(ClassMember::ClassProperty(ClassPropertyMember::{
              name: member_name,
              type_: prop_type,
              visibility,
              is_static: is_static_member,
              readonly_: is_readonly,
              optional: is_optional
            }))
          }
          None => None
        }
      }
    }
    _ => None
  }
}

// Parse top-level declaration
pub fn parse_declaration(self : Parser) -> Option[Declaration] {
  match self.current_token {
    Interface => self.parse_interface().map(fn(iface) { Declaration::Interface(iface) })
    Function => self.parse_function_declaration().map(fn(func) { Declaration::Function(func) })
    Class => self.parse_class().map(fn(cls) { Declaration::Class(cls) })
    Export => {
      self.next_token() // Move past export
      match self.parse_declaration() {
        Some(decl) => {
          Some(Declaration::Export(ExportDeclaration::{
            declaration: Some(decl),
            named_exports: [],
            from: None
          }))
        }
        None => None
      }
    }
    _ => None
  }
}