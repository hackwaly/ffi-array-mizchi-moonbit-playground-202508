// WIT Parser

pub struct Parser {
  tokens : Array[Token]
  mut position : Int
  mut current_token : Token
} derive(Show)

// Parser error
pub struct ParseError {
  message : String
} derive(Show, Eq)

// Create a new parser
pub fn Parser::new(tokens : Array[Token]) -> Parser {
  let init_token = if tokens.length() > 0 { tokens[0] } else { Token::Eof }
  { tokens, position: 0, current_token: init_token }
}

// Advance to the next token
fn advance(self : Parser) -> Unit {
  self.position += 1
  if self.position < self.tokens.length() {
    self.current_token = self.tokens[self.position]
  } else {
    self.current_token = Token::Eof
  }
}

// Peek at the next token
fn peek(self : Parser) -> Token {
  if self.position + 1 < self.tokens.length() {
    self.tokens[self.position + 1]
  } else {
    Token::Eof
  }
}

// Check if current token matches expected
fn expect(self : Parser, expected : Token) -> Result[Unit, ParseError] {
  if self.current_token == expected {
    self.advance()
    Ok(())
  } else {
    Err({ message: "Expected " + expected.to_string() + " but got " + self.current_token.to_string() })
  }
}

// Get identifier from current token
fn expect_identifier(self : Parser) -> Result[String, ParseError] {
  match self.current_token {
    Token::Identifier(name) => {
      self.advance()
      Ok(name)
    }
    _ => Err({ message: "Expected identifier but got " + self.current_token.to_string() })
  }
}

// Parse WIT document
pub fn parse_document(self : Parser) -> Result[WitDocument, ParseError] {
  // Prepare optional package name and items
  let mut package_name_opt : Option[String] = None
  
  // Check for optional package declaration
  if self.current_token == Token::Package {
    self.advance()
    let package_name = match self.parse_package_path() { Ok(v) => v, Err(e) => return Err(e) }
    package_name_opt = Some(package_name)
    match self.expect(Token::Semicolon) { Ok(_) => (), Err(e) => return Err(e) }
  }
  
  // Parse top-level items
  let items : Array[TopLevelItem] = []
  while self.current_token != Token::Eof {
    let item = match self.parse_top_level_item() { Ok(v) => v, Err(e) => return Err(e) }
    items.push(item)
  }
  
  Ok({ package_name: package_name_opt, items })
}

// Parse package path (e.g., "wasi:io@0.1.0")
fn parse_package_path(self : Parser) -> Result[String, ParseError] {
  let path = StringBuilder::new()
  
  // Parse namespace:package
  let namespace = match self.expect_identifier() { Ok(v) => v, Err(e) => return Err(e) }
  path.write_string(namespace)
  
  match self.expect(Token::Colon) { Ok(_) => (), Err(e) => return Err(e) }
  path.write_char(':')
  
  let package = match self.expect_identifier() { Ok(v) => v, Err(e) => return Err(e) }
  path.write_string(package)
  
  // Optional version
  if self.current_token == Token::Identifier("@") {
    self.advance()
    path.write_char('@')
    // Version parsing would go here
  }
  
  Ok(path.to_string())
}

// Parse top-level item
fn parse_top_level_item(self : Parser) -> Result[TopLevelItem, ParseError] {
  match self.current_token {
    Token::Interface => {
      self.advance()
      let interface = match self.parse_interface() {
  Ok(v) => v
  Err(e) => return Err(e)
}
      Ok(TopLevelItem::Interface(interface))
    }
    Token::World => {
      self.advance()
      let world = match self.parse_world() {
  Ok(v) => v
  Err(e) => return Err(e)
}
      Ok(TopLevelItem::World(world))
    }
    Token::Use => {
      self.advance()
      let use_item = match self.parse_use() {
  Ok(v) => v
  Err(e) => return Err(e)
}
      Ok(TopLevelItem::Use(use_item))
    }
    _ => Err({ message: "Expected interface, world, or use at top level" })
  }
}

// Parse interface
fn parse_interface(self : Parser) -> Result[Interface, ParseError] {
  let name = match self.expect_identifier() {
  Ok(v) => v
  Err(e) => return Err(e)
}
  match self.expect(Token::LeftBrace) { Ok(_) => (), Err(e) => return Err(e) }
  
  let interface = Interface::new(name)
  
  while self.current_token != Token::RightBrace && self.current_token != Token::Eof {
    let item = match self.parse_interface_item() {
  Ok(v) => v
  Err(e) => return Err(e)
}
    interface.items.push(item)
  }
  
  match self.expect(Token::RightBrace) { Ok(_) => (), Err(e) => return Err(e) }
  Ok(interface)
}

// Parse interface item
fn parse_interface_item(self : Parser) -> Result[InterfaceItem, ParseError] {
  match self.current_token {
    Token::Use => {
      self.advance()
      let use_item = match self.parse_use() {
  Ok(v) => v
  Err(e) => return Err(e)
}
      Ok(InterfaceItem::Use(use_item))
    }
    Token::Type => {
      self.advance()
      let type_def = match self.parse_type_def() {
  Ok(v) => v
  Err(e) => return Err(e)
}
      Ok(InterfaceItem::Type(type_def))
    }
    Token::Export => {
      self.advance()
      let name = match self.expect_identifier() {
  Ok(v) => v
  Err(e) => return Err(e)
}
      match self.expect(Token::Semicolon) { Ok(_) => (), Err(e) => return Err(e) }
      Ok(InterfaceItem::Export(name))
    }
    Token::Identifier(_) => {
      // Function declaration
      let func = match self.parse_function() {
  Ok(v) => v
  Err(e) => return Err(e)
}
      Ok(InterfaceItem::Function(func))
    }
    _ => Err({ message: "Expected interface item" })
  }
}

// Parse world
fn parse_world(self : Parser) -> Result[World, ParseError] {
  let name = match self.expect_identifier() {
  Ok(v) => v
  Err(e) => return Err(e)
}
  match self.expect(Token::LeftBrace) { Ok(_) => (), Err(e) => return Err(e) }
  
  let world = World::new(name)
  
  while self.current_token != Token::RightBrace && self.current_token != Token::Eof {
    let item = match self.parse_world_item() {
  Ok(v) => v
  Err(e) => return Err(e)
}
    world.items.push(item)
  }
  
  match self.expect(Token::RightBrace) { Ok(_) => (), Err(e) => return Err(e) }
  Ok(world)
}

// Parse world item
fn parse_world_item(self : Parser) -> Result[WorldItem, ParseError] {
  match self.current_token {
    Token::Use => {
      self.advance()
      let use_item = match self.parse_use() {
  Ok(v) => v
  Err(e) => return Err(e)
}
      Ok(WorldItem::Use(use_item))
    }
    Token::Type => {
      self.advance()
      let type_def = match self.parse_type_def() {
  Ok(v) => v
  Err(e) => return Err(e)
}
      Ok(WorldItem::Type(type_def))
    }
    Token::Import => {
      self.advance()
      let import = match self.parse_import() {
  Ok(v) => v
  Err(e) => return Err(e)
}
      Ok(WorldItem::Import(import))
    }
    Token::Export => {
      self.advance()
      let export = match self.parse_export() {
  Ok(v) => v
  Err(e) => return Err(e)
}
      Ok(WorldItem::Export(export))
    }
    _ => Err({ message: "Expected world item" })
  }
}

// Parse import
fn parse_import(self : Parser) -> Result[Import, ParseError] {
  let name = match self.expect_identifier() {
  Ok(v) => v
  Err(e) => return Err(e)
}
  match self.expect(Token::Colon) { Ok(_) => (), Err(e) => return Err(e) }
  
  let kind = if self.current_token == Token::Func {
    self.advance()
    let func = match self.parse_function_signature() {
  Ok(v) => v
  Err(e) => return Err(e)
}
    ImportKind::Function(func)
  } else if self.current_token == Token::Interface {
    self.advance()
    let interface_path = match self.parse_interface_path() {
  Ok(v) => v
  Err(e) => return Err(e)
}
    ImportKind::Interface(interface_path)
  } else {
    return Err({ message: "Expected func or interface after import" })
  }
  
  Ok({ name, kind })
}

// Parse export
fn parse_export(self : Parser) -> Result[Export, ParseError] {
  let name = match self.expect_identifier() {
  Ok(v) => v
  Err(e) => return Err(e)
}
  match self.expect(Token::Colon) { Ok(_) => (), Err(e) => return Err(e) }
  
  let kind = if self.current_token == Token::Func {
    self.advance()
    let func = match self.parse_function_signature() {
  Ok(v) => v
  Err(e) => return Err(e)
}
    ExportKind::Function(func)
  } else if self.current_token == Token::Interface {
    self.advance()
    let interface_path = match self.parse_interface_path() {
  Ok(v) => v
  Err(e) => return Err(e)
}
    ExportKind::Interface(interface_path)
  } else {
    return Err({ message: "Expected func or interface after export" })
  }
  
  Ok({ name, kind })
}

// Parse interface path
fn parse_interface_path(self : Parser) -> Result[String, ParseError] {
  // For now, just parse as identifier
  self.expect_identifier()
}

// Parse use statement
fn parse_use(self : Parser) -> Result[UseItem, ParseError] {
  let path = match self.parse_use_path() {
  Ok(v) => v
  Err(e) => return Err(e)
}
  match self.expect(Token::Dot) { Ok(_) => (), Err(e) => return Err(e) }
  
  let items = if self.current_token == Token::Star {
    self.advance()
    UseItemSpec::All
  } else if self.current_token == Token::LeftBrace {
    self.advance()
    let names = match self.parse_comma_separated_identifiers() {
  Ok(v) => v
  Err(e) => return Err(e)
}
    match self.expect(Token::RightBrace) { Ok(_) => (), Err(e) => return Err(e) }
    UseItemSpec::Named(names)
  } else {
    return Err({ message: "Expected * or { after use path" })
  }
  
  match self.expect(Token::Semicolon) { Ok(_) => (), Err(e) => return Err(e) }
  Ok({ path, items: [items] })
}

// Parse use path
fn parse_use_path(self : Parser) -> Result[String, ParseError] {
  let mut path = StringBuilder::new()
  
  // Parse first part
  let first = match self.expect_identifier() {
  Ok(v) => v
  Err(e) => return Err(e)
}
  path.write_string(first)
  
  // Parse optional :package/interface parts
  while self.current_token == Token::Colon || self.current_token == Token::Slash {
    match self.current_token {
      Token::Colon => {
        self.advance()
        path.write_char(':')
      }
      Token::Slash => {
        self.advance()
        path.write_char('/')
      }
      _ => break
    }
    let part = match self.expect_identifier() {
  Ok(v) => v
  Err(e) => return Err(e)
}
    path.write_string(part)
  }
  
  Ok(path.to_string())
}

// Parse comma-separated identifiers
fn parse_comma_separated_identifiers(self : Parser) -> Result[Array[String], ParseError] {
  let mut names : Array[String] = []
  
  // Parse first identifier
  let first = match self.expect_identifier() {
  Ok(v) => v
  Err(e) => return Err(e)
}
  names.push(first)
  
  // Parse remaining identifiers
  while self.current_token == Token::Comma {
    self.advance() // consume comma
    let name = match self.expect_identifier() {
  Ok(v) => v
  Err(e) => return Err(e)
}
    names.push(name)
  }
  
  Ok(names)
}

// Parse type definition
fn parse_type_def(self : Parser) -> Result[TypeDef, ParseError] {
  let name = match self.expect_identifier() {
  Ok(v) => v
  Err(e) => return Err(e)
}
  match self.expect(Token::Equals) { Ok(_) => (), Err(e) => return Err(e) }
  
  let def = match self.parse_type_def_kind() {
  Ok(v) => v
  Err(e) => return Err(e)
}
  
  Ok({ name, def })
}

// Parse type definition kind
fn parse_type_def_kind(self : Parser) -> Result[TypeDefKind, ParseError] {
  match self.current_token {
    Token::Record => {
      self.advance()
      let record = match self.parse_record() {
  Ok(v) => v
  Err(e) => return Err(e)
}
      Ok(TypeDefKind::Record(record))
    }
    Token::Enum => {
      self.advance()
      let enum_ = match self.parse_enum() {
  Ok(v) => v
  Err(e) => return Err(e)
}
      Ok(TypeDefKind::Enum(enum_))
    }
    Token::Flags => {
      self.advance()
      let flags = match self.parse_flags() {
  Ok(v) => v
  Err(e) => return Err(e)
}
      Ok(TypeDefKind::Flags(flags))
    }
    Token::Variant => {
      self.advance()
      let variant = match self.parse_variant() {
  Ok(v) => v
  Err(e) => return Err(e)
}
      Ok(TypeDefKind::Variant(variant))
    }
    Token::Resource => {
      self.advance()
      let resource = match self.parse_resource() {
  Ok(v) => v
  Err(e) => return Err(e)
}
      Ok(TypeDefKind::Resource(resource))
    }
    _ => {
      // Type alias
      let typ = match self.parse_type() {
  Ok(v) => v
  Err(e) => return Err(e)
}
      match self.expect(Token::Semicolon) { Ok(_) => (), Err(e) => return Err(e) }
      Ok(TypeDefKind::Alias(typ))
    }
  }
}

// Parse record
fn parse_record(self : Parser) -> Result[Record, ParseError] {
  match self.expect(Token::LeftBrace) { Ok(_) => (), Err(e) => return Err(e) }
  
  let record = Record::new()
  
  while self.current_token != Token::RightBrace && self.current_token != Token::Eof {
    let field = match self.parse_field() {
  Ok(v) => v
  Err(e) => return Err(e)
}
    record.fields.push(field)
    
    // Optional comma
    if self.current_token == Token::Comma {
      self.advance()
    }
  }
  
  match self.expect(Token::RightBrace) { Ok(_) => (), Err(e) => return Err(e) }
  Ok(record)
}

// Parse field
fn parse_field(self : Parser) -> Result[Field, ParseError] {
  let name = match self.expect_identifier() {
  Ok(v) => v
  Err(e) => return Err(e)
}
  match self.expect(Token::Colon) { Ok(_) => (), Err(e) => return Err(e) }
  let typ = match self.parse_type() {
  Ok(v) => v
  Err(e) => return Err(e)
}
  
  Ok({ name, typ })
}

// Parse enum
fn parse_enum(self : Parser) -> Result[Enum, ParseError] {
  match self.expect(Token::LeftBrace) { Ok(_) => (), Err(e) => return Err(e) }
  
  let enum_ = Enum::new()
  
  while self.current_token != Token::RightBrace && self.current_token != Token::Eof {
    let case = match self.expect_identifier() {
  Ok(v) => v
  Err(e) => return Err(e)
}
    enum_.cases.push(case)
    
    // Optional comma
    if self.current_token == Token::Comma {
      self.advance()
    }
  }
  
  match self.expect(Token::RightBrace) { Ok(_) => (), Err(e) => return Err(e) }
  Ok(enum_)
}

// Parse flags
fn parse_flags(self : Parser) -> Result[Flags, ParseError] {
  match self.expect(Token::LeftBrace) { Ok(_) => (), Err(e) => return Err(e) }
  
  let flags = Flags::new()
  
  while self.current_token != Token::RightBrace && self.current_token != Token::Eof {
    let flag = match self.expect_identifier() {
  Ok(v) => v
  Err(e) => return Err(e)
}
    flags.flags.push(flag)
    
    // Optional comma
    if self.current_token == Token::Comma {
      self.advance()
    }
  }
  
  match self.expect(Token::RightBrace) { Ok(_) => (), Err(e) => return Err(e) }
  Ok(flags)
}

// Parse variant
fn parse_variant(self : Parser) -> Result[Variant, ParseError] {
  match self.expect(Token::LeftBrace) { Ok(_) => (), Err(e) => return Err(e) }
  
  let variant = Variant::new()
  
  while self.current_token != Token::RightBrace && self.current_token != Token::Eof {
    let case = match self.parse_variant_case() {
  Ok(v) => v
  Err(e) => return Err(e)
}
    variant.cases.push(case)
    
    // Optional comma
    if self.current_token == Token::Comma {
      self.advance()
    }
  }
  
  match self.expect(Token::RightBrace) { Ok(_) => (), Err(e) => return Err(e) }
  Ok(variant)
}

// Parse variant case
fn parse_variant_case(self : Parser) -> Result[VariantCase, ParseError] {
  let name = match self.expect_identifier() {
  Ok(v) => v
  Err(e) => return Err(e)
}
  
  let typ = if self.current_token == Token::LeftParen {
    self.advance()
    let t = match self.parse_type() {
  Ok(v) => v
  Err(e) => return Err(e)
}
    match self.expect(Token::RightParen) { Ok(_) => (), Err(e) => return Err(e) }
    Some(t)
  } else {
    None
  }
  
  Ok({ name, typ })
}

// Parse resource
fn parse_resource(self : Parser) -> Result[Resource, ParseError] {
  match self.expect(Token::LeftBrace) { Ok(_) => (), Err(e) => return Err(e) }
  
  let resource = Resource::new()
  
  while self.current_token != Token::RightBrace && self.current_token != Token::Eof {
    let method = match self.parse_resource_method() {
  Ok(v) => v
  Err(e) => return Err(e)
}
    resource.methods.push(method)
  }
  
  match self.expect(Token::RightBrace) { Ok(_) => (), Err(e) => return Err(e) }
  Ok(resource)
}

// Parse resource method
fn parse_resource_method(self : Parser) -> Result[ResourceMethod, ParseError] {
  match self.current_token {
    Token::Constructor => {
      self.advance()
      let params = match self.parse_function_params() {
  Ok(v) => v
  Err(e) => return Err(e)
}
      match self.expect(Token::Semicolon) { Ok(_) => (), Err(e) => return Err(e) }
      Ok({ name: "constructor", kind: MethodKind::Constructor(params) })
    }
    Token::Identifier(name) => {
      self.advance()
      match self.expect(Token::Colon) { Ok(_) => (), Err(e) => return Err(e) }
      
      if self.current_token == Token::Method {
        self.advance()
        let func = match self.parse_function_signature() {
  Ok(v) => v
  Err(e) => return Err(e)
}
        Ok({ name, kind: MethodKind::Method(func) })
      } else if self.current_token == Token::Static {
        self.advance()
        let func = match self.parse_function_signature() {
  Ok(v) => v
  Err(e) => return Err(e)
}
        Ok({ name, kind: MethodKind::Static(func) })
      } else {
        return Err({ message: "Expected method or static" })
      }
    }
    _ => Err({ message: "Expected resource method" })
  }
}

// Parse function
fn parse_function(self : Parser) -> Result[Function, ParseError] {
  let name = match self.expect_identifier() {
  Ok(v) => v
  Err(e) => return Err(e)
}
  match self.expect(Token::Colon) { Ok(_) => (), Err(e) => return Err(e) }
  match self.expect(Token::Func) { Ok(_) => (), Err(e) => return Err(e) }
  
  self.parse_function_signature()
}

// Parse function signature
fn parse_function_signature(self : Parser) -> Result[Function, ParseError] {
  let params = match self.parse_function_params() {
  Ok(v) => v
  Err(e) => return Err(e)
}
  
  let results = if self.current_token == Token::Arrow {
    self.advance()
    match self.parse_function_result() {
      Ok(v) => v
      Err(e) => return Err(e)
    }
  } else {
    FunctionResult::None
  }
  
  match self.expect(Token::Semicolon) { Ok(_) => (), Err(e) => return Err(e) }
  
  Ok({ name: "", params, results })
}

// Parse function parameters
fn parse_function_params(self : Parser) -> Result[Array[Param], ParseError] {
  match self.expect(Token::LeftParen) { Ok(_) => (), Err(e) => return Err(e) }
  
  let mut params : Array[Param] = []
  
  while self.current_token != Token::RightParen && self.current_token != Token::Eof {
    let param = match self.parse_param() {
  Ok(v) => v
  Err(e) => return Err(e)
}
    params.push(param)
    
    if self.current_token == Token::Comma {
      self.advance()
    }
  }
  
  match self.expect(Token::RightParen) { Ok(_) => (), Err(e) => return Err(e) }
  Ok(params)
}

// Parse parameter
fn parse_param(self : Parser) -> Result[Param, ParseError] {
  let name = match self.expect_identifier() {
  Ok(v) => v
  Err(e) => return Err(e)
}
  match self.expect(Token::Colon) { Ok(_) => (), Err(e) => return Err(e) }
  let typ = match self.parse_type() {
  Ok(v) => v
  Err(e) => return Err(e)
}
  
  Ok({ name, typ })
}

// Parse function result
fn parse_function_result(self : Parser) -> Result[FunctionResult, ParseError] {
  if self.current_token == Token::LeftParen {
    // Named results
    self.advance()
    let mut results : Array[Param] = []
    
    while self.current_token != Token::RightParen && self.current_token != Token::Eof {
      let result = match self.parse_param() {
  Ok(v) => v
  Err(e) => return Err(e)
}
      results.push(result)
      
      if self.current_token == Token::Comma {
        self.advance()
      }
    }
    
    match self.expect(Token::RightParen) { Ok(_) => (), Err(e) => return Err(e) }
    Ok(FunctionResult::Named(results))
  } else {
    // Single result
    let typ = match self.parse_type() {
  Ok(v) => v
  Err(e) => return Err(e)
}
    Ok(FunctionResult::Single(typ))
  }
}

// Parse type
fn parse_type(self : Parser) -> Result[Type, ParseError] {
  match self.current_token {
    // Primitive types
    Token::Bool => { self.advance(); Ok(Type::Bool) }
    Token::S8 => { self.advance(); Ok(Type::S8) }
    Token::S16 => { self.advance(); Ok(Type::S16) }
    Token::S32 => { self.advance(); Ok(Type::S32) }
    Token::S64 => { self.advance(); Ok(Type::S64) }
    Token::U8 => { self.advance(); Ok(Type::U8) }
    Token::U16 => { self.advance(); Ok(Type::U16) }
    Token::U32 => { self.advance(); Ok(Type::U32) }
    Token::U64 => { self.advance(); Ok(Type::U64) }
    Token::F32 => { self.advance(); Ok(Type::F32) }
    Token::F64 => { self.advance(); Ok(Type::F64) }
    Token::Char => { self.advance(); Ok(Type::Char) }
    Token::String => { self.advance(); Ok(Type::String) }
    
    // Compound types
    Token::List => {
      self.advance()
      match self.expect(Token::LeftAngle) { Ok(_) => (), Err(e) => return Err(e) }
      let elem_type = match self.parse_type() {
  Ok(v) => v
  Err(e) => return Err(e)
}
      match self.expect(Token::RightAngle) { Ok(_) => (), Err(e) => return Err(e) }
      Ok(Type::List(elem_type))
    }
    
    Token::Option => {
      self.advance()
      match self.expect(Token::LeftAngle) { Ok(_) => (), Err(e) => return Err(e) }
      let inner_type = match self.parse_type() {
  Ok(v) => v
  Err(e) => return Err(e)
}
      match self.expect(Token::RightAngle) { Ok(_) => (), Err(e) => return Err(e) }
      Ok(Type::Option(inner_type))
    }
    
    Token::Result => {
      self.advance()
      match self.expect(Token::LeftAngle) { Ok(_) => (), Err(e) => return Err(e) }
      
      let ok_type = if self.current_token == Token::Comma {
        None
      } else {
        match self.parse_type() {
          Ok(v) => Some(v)
          Err(e) => return Err(e)
        }
      }
      
      match self.expect(Token::Comma) { Ok(_) => (), Err(e) => return Err(e) }
      
      let err_type = if self.current_token == Token::RightAngle {
        None
      } else {
        match self.parse_type() {
          Ok(v) => Some(v)
          Err(e) => return Err(e)
        }
      }
      
      match self.expect(Token::RightAngle) { Ok(_) => (), Err(e) => return Err(e) }
      Ok(Type::Result(ok_type, err_type))
    }
    
    Token::Tuple => {
      self.advance()
      match self.expect(Token::LeftAngle) { Ok(_) => (), Err(e) => return Err(e) }
      
      let mut types : Array[Type] = []
      while self.current_token != Token::RightAngle && self.current_token != Token::Eof {
        let typ = match self.parse_type() {
  Ok(v) => v
  Err(e) => return Err(e)
}
        types.push(typ)
        
        if self.current_token == Token::Comma {
          self.advance()
        }
      }
      
      match self.expect(Token::RightAngle) { Ok(_) => (), Err(e) => return Err(e) }
      Ok(Type::Tuple(types))
    }
    
    Token::Borrow => {
      self.advance()
      match self.expect(Token::LeftAngle) { Ok(_) => (), Err(e) => return Err(e) }
      let resource_name = match self.expect_identifier() {
  Ok(v) => v
  Err(e) => return Err(e)
}
      match self.expect(Token::RightAngle) { Ok(_) => (), Err(e) => return Err(e) }
      Ok(Type::Borrow(resource_name))
    }
    
    Token::Own => {
      self.advance()
      match self.expect(Token::LeftAngle) { Ok(_) => (), Err(e) => return Err(e) }
      let resource_name = match self.expect_identifier() {
  Ok(v) => v
  Err(e) => return Err(e)
}
      match self.expect(Token::RightAngle) { Ok(_) => (), Err(e) => return Err(e) }
      Ok(Type::Own(resource_name))
    }
    
    Token::Identifier(name) => {
      self.advance()
      Ok(Type::Named(name))
    }
    
    _ => Err({ message: "Expected type but got " + self.current_token.to_string() })
  }
}

// Main parse function
pub fn parse_wit(input : String) -> Result[WitDocument, ParseError] {
  let tokens = tokenize(input)
  let parser = Parser::new(tokens)
  parser.parse_document()
}
