// WIT Parser

pub struct Parser {
  tokens : Array[Token]
  position : Int
  current_token : Token
} derive(Debug, Show)

// Parser error
pub struct ParseError {
  message : String
} derive(Debug, Show, Eq)

// Create a new parser
pub fn Parser::new(tokens : Array[Token]) -> Parser {
  let parser = { tokens, position: 0, current_token: Token::Eof }
  if tokens.length() > 0 {
    parser.current_token = tokens[0]
  }
  parser
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
  let doc = WitDocument::new()
  
  // Check for optional package declaration
  if self.current_token == Token::Package {
    self.advance()
    let package_name = self.parse_package_path()?
    doc.package_name = Some(package_name)
    self.expect(Token::Semicolon)?
  }
  
  // Parse top-level items
  while self.current_token != Token::Eof {
    let item = self.parse_top_level_item()?
    doc.items.push(item)
  }
  
  Ok(doc)
}

// Parse package path (e.g., "wasi:io@0.1.0")
fn parse_package_path(self : Parser) -> Result[String, ParseError] {
  let mut path = StringBuilder::new()
  
  // Parse namespace:package
  let namespace = self.expect_identifier()?
  path.write_string(namespace)
  
  self.expect(Token::Colon)?
  path.write_char(':')
  
  let package = self.expect_identifier()?
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
      let interface = self.parse_interface()?
      Ok(TopLevelItem::Interface(interface))
    }
    Token::World => {
      self.advance()
      let world = self.parse_world()?
      Ok(TopLevelItem::World(world))
    }
    Token::Use => {
      self.advance()
      let use_item = self.parse_use()?
      Ok(TopLevelItem::Use(use_item))
    }
    _ => Err({ message: "Expected interface, world, or use at top level" })
  }
}

// Parse interface
fn parse_interface(self : Parser) -> Result[Interface, ParseError] {
  let name = self.expect_identifier()?
  self.expect(Token::LeftBrace)?
  
  let interface = Interface::new(name)
  
  while self.current_token != Token::RightBrace && self.current_token != Token::Eof {
    let item = self.parse_interface_item()?
    interface.items.push(item)
  }
  
  self.expect(Token::RightBrace)?
  Ok(interface)
}

// Parse interface item
fn parse_interface_item(self : Parser) -> Result[InterfaceItem, ParseError] {
  match self.current_token {
    Token::Use => {
      self.advance()
      let use_item = self.parse_use()?
      Ok(InterfaceItem::Use(use_item))
    }
    Token::Type => {
      self.advance()
      let type_def = self.parse_type_def()?
      Ok(InterfaceItem::Type(type_def))
    }
    Token::Export => {
      self.advance()
      let name = self.expect_identifier()?
      self.expect(Token::Semicolon)?
      Ok(InterfaceItem::Export(name))
    }
    Token::Identifier(_) => {
      // Function declaration
      let func = self.parse_function()?
      Ok(InterfaceItem::Function(func))
    }
    _ => Err({ message: "Expected interface item" })
  }
}

// Parse world
fn parse_world(self : Parser) -> Result[World, ParseError] {
  let name = self.expect_identifier()?
  self.expect(Token::LeftBrace)?
  
  let world = World::new(name)
  
  while self.current_token != Token::RightBrace && self.current_token != Token::Eof {
    let item = self.parse_world_item()?
    world.items.push(item)
  }
  
  self.expect(Token::RightBrace)?
  Ok(world)
}

// Parse world item
fn parse_world_item(self : Parser) -> Result[WorldItem, ParseError] {
  match self.current_token {
    Token::Use => {
      self.advance()
      let use_item = self.parse_use()?
      Ok(WorldItem::Use(use_item))
    }
    Token::Type => {
      self.advance()
      let type_def = self.parse_type_def()?
      Ok(WorldItem::Type(type_def))
    }
    Token::Import => {
      self.advance()
      let import = self.parse_import()?
      Ok(WorldItem::Import(import))
    }
    Token::Export => {
      self.advance()
      let export = self.parse_export()?
      Ok(WorldItem::Export(export))
    }
    _ => Err({ message: "Expected world item" })
  }
}

// Parse import
fn parse_import(self : Parser) -> Result[Import, ParseError] {
  let name = self.expect_identifier()?
  self.expect(Token::Colon)?
  
  let kind = if self.current_token == Token::Func {
    self.advance()
    let func = self.parse_function_signature()?
    ImportKind::Function(func)
  } else if self.current_token == Token::Interface {
    self.advance()
    let interface_path = self.parse_interface_path()?
    ImportKind::Interface(interface_path)
  } else {
    return Err({ message: "Expected func or interface after import" })
  }
  
  Ok({ name, kind })
}

// Parse export
fn parse_export(self : Parser) -> Result[Export, ParseError] {
  let name = self.expect_identifier()?
  self.expect(Token::Colon)?
  
  let kind = if self.current_token == Token::Func {
    self.advance()
    let func = self.parse_function_signature()?
    ExportKind::Function(func)
  } else if self.current_token == Token::Interface {
    self.advance()
    let interface_path = self.parse_interface_path()?
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
  let path = self.parse_use_path()?
  self.expect(Token::Dot)?
  
  let items = if self.current_token == Token::Star {
    self.advance()
    UseItemSpec::All
  } else if self.current_token == Token::LeftBrace {
    self.advance()
    let names = self.parse_comma_separated_identifiers()?
    self.expect(Token::RightBrace)?
    UseItemSpec::Named(names)
  } else {
    return Err({ message: "Expected * or { after use path" })
  }
  
  self.expect(Token::Semicolon)?
  Ok({ path, items: [items] })
}

// Parse use path
fn parse_use_path(self : Parser) -> Result[String, ParseError] {
  let mut path = StringBuilder::new()
  
  // Parse first part
  let first = self.expect_identifier()?
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
    let part = self.expect_identifier()?
    path.write_string(part)
  }
  
  Ok(path.to_string())
}

// Parse comma-separated identifiers
fn parse_comma_separated_identifiers(self : Parser) -> Result[Array[String], ParseError] {
  let mut names : Array[String] = []
  
  // Parse first identifier
  let first = self.expect_identifier()?
  names.push(first)
  
  // Parse remaining identifiers
  while self.current_token == Token::Comma {
    self.advance() // consume comma
    let name = self.expect_identifier()?
    names.push(name)
  }
  
  Ok(names)
}

// Parse type definition
fn parse_type_def(self : Parser) -> Result[TypeDef, ParseError] {
  let name = self.expect_identifier()?
  self.expect(Token::Equals)?
  
  let def = self.parse_type_def_kind()?
  
  Ok({ name, def })
}

// Parse type definition kind
fn parse_type_def_kind(self : Parser) -> Result[TypeDefKind, ParseError] {
  match self.current_token {
    Token::Record => {
      self.advance()
      let record = self.parse_record()?
      Ok(TypeDefKind::Record(record))
    }
    Token::Enum => {
      self.advance()
      let enum_ = self.parse_enum()?
      Ok(TypeDefKind::Enum(enum_))
    }
    Token::Flags => {
      self.advance()
      let flags = self.parse_flags()?
      Ok(TypeDefKind::Flags(flags))
    }
    Token::Variant => {
      self.advance()
      let variant = self.parse_variant()?
      Ok(TypeDefKind::Variant(variant))
    }
    Token::Resource => {
      self.advance()
      let resource = self.parse_resource()?
      Ok(TypeDefKind::Resource(resource))
    }
    _ => {
      // Type alias
      let typ = self.parse_type()?
      self.expect(Token::Semicolon)?
      Ok(TypeDefKind::Alias(typ))
    }
  }
}

// Parse record
fn parse_record(self : Parser) -> Result[Record, ParseError] {
  self.expect(Token::LeftBrace)?
  
  let record = Record::new()
  
  while self.current_token != Token::RightBrace && self.current_token != Token::Eof {
    let field = self.parse_field()?
    record.fields.push(field)
    
    // Optional comma
    if self.current_token == Token::Comma {
      self.advance()
    }
  }
  
  self.expect(Token::RightBrace)?
  Ok(record)
}

// Parse field
fn parse_field(self : Parser) -> Result[Field, ParseError] {
  let name = self.expect_identifier()?
  self.expect(Token::Colon)?
  let typ = self.parse_type()?
  
  Ok({ name, typ })
}

// Parse enum
fn parse_enum(self : Parser) -> Result[Enum, ParseError] {
  self.expect(Token::LeftBrace)?
  
  let enum_ = Enum::new()
  
  while self.current_token != Token::RightBrace && self.current_token != Token::Eof {
    let case = self.expect_identifier()?
    enum_.cases.push(case)
    
    // Optional comma
    if self.current_token == Token::Comma {
      self.advance()
    }
  }
  
  self.expect(Token::RightBrace)?
  Ok(enum_)
}

// Parse flags
fn parse_flags(self : Parser) -> Result[Flags, ParseError] {
  self.expect(Token::LeftBrace)?
  
  let flags = Flags::new()
  
  while self.current_token != Token::RightBrace && self.current_token != Token::Eof {
    let flag = self.expect_identifier()?
    flags.flags.push(flag)
    
    // Optional comma
    if self.current_token == Token::Comma {
      self.advance()
    }
  }
  
  self.expect(Token::RightBrace)?
  Ok(flags)
}

// Parse variant
fn parse_variant(self : Parser) -> Result[Variant, ParseError] {
  self.expect(Token::LeftBrace)?
  
  let variant = Variant::new()
  
  while self.current_token != Token::RightBrace && self.current_token != Token::Eof {
    let case = self.parse_variant_case()?
    variant.cases.push(case)
    
    // Optional comma
    if self.current_token == Token::Comma {
      self.advance()
    }
  }
  
  self.expect(Token::RightBrace)?
  Ok(variant)
}

// Parse variant case
fn parse_variant_case(self : Parser) -> Result[VariantCase, ParseError] {
  let name = self.expect_identifier()?
  
  let typ = if self.current_token == Token::LeftParen {
    self.advance()
    let t = self.parse_type()?
    self.expect(Token::RightParen)?
    Some(t)
  } else {
    None
  }
  
  Ok({ name, typ })
}

// Parse resource
fn parse_resource(self : Parser) -> Result[Resource, ParseError] {
  self.expect(Token::LeftBrace)?
  
  let resource = Resource::new()
  
  while self.current_token != Token::RightBrace && self.current_token != Token::Eof {
    let method = self.parse_resource_method()?
    resource.methods.push(method)
  }
  
  self.expect(Token::RightBrace)?
  Ok(resource)
}

// Parse resource method
fn parse_resource_method(self : Parser) -> Result[ResourceMethod, ParseError] {
  match self.current_token {
    Token::Constructor => {
      self.advance()
      let params = self.parse_function_params()?
      self.expect(Token::Semicolon)?
      Ok({ name: "constructor", kind: MethodKind::Constructor(params) })
    }
    Token::Identifier(name) => {
      self.advance()
      self.expect(Token::Colon)?
      
      if self.current_token == Token::Method {
        self.advance()
        let func = self.parse_function_signature()?
        Ok({ name, kind: MethodKind::Method(func) })
      } else if self.current_token == Token::Static {
        self.advance()
        let func = self.parse_function_signature()?
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
  let name = self.expect_identifier()?
  self.expect(Token::Colon)?
  self.expect(Token::Func)?
  
  self.parse_function_signature()
}

// Parse function signature
fn parse_function_signature(self : Parser) -> Result[Function, ParseError] {
  let params = self.parse_function_params()?
  
  let results = if self.current_token == Token::Arrow {
    self.advance()
    self.parse_function_result()?
  } else {
    FunctionResult::None
  }
  
  self.expect(Token::Semicolon)?
  
  Ok({ name: "", params, results })
}

// Parse function parameters
fn parse_function_params(self : Parser) -> Result[Array[Param], ParseError] {
  self.expect(Token::LeftParen)?
  
  let mut params : Array[Param] = []
  
  while self.current_token != Token::RightParen && self.current_token != Token::Eof {
    let param = self.parse_param()?
    params.push(param)
    
    if self.current_token == Token::Comma {
      self.advance()
    }
  }
  
  self.expect(Token::RightParen)?
  Ok(params)
}

// Parse parameter
fn parse_param(self : Parser) -> Result[Param, ParseError] {
  let name = self.expect_identifier()?
  self.expect(Token::Colon)?
  let typ = self.parse_type()?
  
  Ok({ name, typ })
}

// Parse function result
fn parse_function_result(self : Parser) -> Result[FunctionResult, ParseError] {
  if self.current_token == Token::LeftParen {
    // Named results
    self.advance()
    let mut results : Array[Param] = []
    
    while self.current_token != Token::RightParen && self.current_token != Token::Eof {
      let result = self.parse_param()?
      results.push(result)
      
      if self.current_token == Token::Comma {
        self.advance()
      }
    }
    
    self.expect(Token::RightParen)?
    Ok(FunctionResult::Named(results))
  } else {
    // Single result
    let typ = self.parse_type()?
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
      self.expect(Token::LeftAngle)?
      let elem_type = self.parse_type()?
      self.expect(Token::RightAngle)?
      Ok(Type::List(elem_type))
    }
    
    Token::Option => {
      self.advance()
      self.expect(Token::LeftAngle)?
      let inner_type = self.parse_type()?
      self.expect(Token::RightAngle)?
      Ok(Type::Option(inner_type))
    }
    
    Token::Result => {
      self.advance()
      self.expect(Token::LeftAngle)?
      
      let ok_type = if self.current_token == Token::Comma {
        None
      } else {
        Some(self.parse_type()?)
      }
      
      self.expect(Token::Comma)?
      
      let err_type = if self.current_token == Token::RightAngle {
        None
      } else {
        Some(self.parse_type()?)
      }
      
      self.expect(Token::RightAngle)?
      Ok(Type::Result { ok: ok_type, err: err_type })
    }
    
    Token::Tuple => {
      self.advance()
      self.expect(Token::LeftAngle)?
      
      let mut types : Array[Type] = []
      while self.current_token != Token::RightAngle && self.current_token != Token::Eof {
        let typ = self.parse_type()?
        types.push(typ)
        
        if self.current_token == Token::Comma {
          self.advance()
        }
      }
      
      self.expect(Token::RightAngle)?
      Ok(Type::Tuple(types))
    }
    
    Token::Borrow => {
      self.advance()
      self.expect(Token::LeftAngle)?
      let resource_name = self.expect_identifier()?
      self.expect(Token::RightAngle)?
      Ok(Type::Borrow(resource_name))
    }
    
    Token::Own => {
      self.advance()
      self.expect(Token::LeftAngle)?
      let resource_name = self.expect_identifier()?
      self.expect(Token::RightAngle)?
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