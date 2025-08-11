// WIT Lexer

// Token types
pub enum Token {
  // Keywords
  Interface
  World
  Use
  Type
  Record
  Enum
  Flags
  Variant
  Resource
  Func
  Import
  Export
  Package
  Constructor
  Method
  Static
  
  // Types
  Bool
  S8
  S16
  S32
  S64
  U8
  U16
  U32
  U64
  F32
  F64
  Char
  String
  List
  Option
  Result
  Tuple
  Borrow
  Own
  
  // Identifiers and literals
  Identifier(String)
  StringLiteral(String)
  IntegerLiteral(Int64)
  
  // Punctuation
  LeftBrace     // {
  RightBrace    // }
  LeftParen     // (
  RightParen    // )
  LeftAngle     // <
  RightAngle    // >
  Comma         // ,
  Colon         // :
  Semicolon     // ;
  Arrow         // ->
  Dot           // .
  Slash         // /
  Star          // *
  Equals        // =
  
  // Special
  Eof
  Newline
} derive(Debug, Show, Eq)

// Lexer state
pub struct Lexer {
  input : String
  position : Int
  current_char : Option[Char]
} derive(Debug, Show)

// Create a new lexer
pub fn Lexer::new(input : String) -> Lexer {
  let lexer = { input, position: 0, current_char: None }
  lexer.read_char()
  lexer
}

// Read the next character
fn read_char(self : Lexer) -> Unit {
  if self.position >= self.input.length() {
    self.current_char = None
  } else {
    self.current_char = Some(self.input[self.position])
    self.position += 1
  }
}

// Peek at the next character without consuming it
fn peek_char(self : Lexer) -> Option[Char] {
  if self.position >= self.input.length() {
    None
  } else {
    Some(self.input[self.position])
  }
}

// Skip whitespace
fn skip_whitespace(self : Lexer) -> Unit {
  while true {
    match self.current_char {
      Some(' ') | Some('\t') | Some('\r') => self.read_char()
      _ => break
    }
  }
}

// Skip line comments
fn skip_line_comment(self : Lexer) -> Unit {
  // Skip until newline or EOF
  while self.current_char != Some('\n') && self.current_char != None {
    self.read_char()
  }
}

// Skip block comments
fn skip_block_comment(self : Lexer) -> Unit {
  // Skip /* ... */
  while self.current_char != None {
    if self.current_char == Some('*') && self.peek_char() == Some('/') {
      self.read_char() // consume *
      self.read_char() // consume /
      break
    }
    self.read_char()
  }
}

// Read an identifier or keyword
fn read_identifier(self : Lexer) -> String {
  let start = self.position - 1
  
  while true {
    match self.current_char {
      Some(ch) => {
        if is_identifier_char(ch) {
          self.read_char()
        } else {
          break
        }
      }
      None => break
    }
  }
  
  self.input.substring(start, self.position - 1)
}

// Read a string literal
fn read_string_literal(self : Lexer) -> String {
  self.read_char() // Skip opening quote
  let mut result = StringBuilder::new()
  
  while self.current_char != Some('"') && self.current_char != None {
    match self.current_char {
      Some('\\') => {
        self.read_char()
        match self.current_char {
          Some('n') => result.write_char('\n')
          Some('r') => result.write_char('\r')
          Some('t') => result.write_char('\t')
          Some('\\') => result.write_char('\\')
          Some('"') => result.write_char('"')
          Some(ch) => result.write_char(ch)
          None => break
        }
      }
      Some(ch) => result.write_char(ch)
      None => break
    }
    self.read_char()
  }
  
  if self.current_char == Some('"') {
    self.read_char() // Skip closing quote
  }
  
  result.to_string()
}

// Read an integer literal
fn read_integer_literal(self : Lexer) -> Int64 {
  let start = self.position - 1
  
  while true {
    match self.current_char {
      Some(ch) => {
        if ch >= '0' && ch <= '9' {
          self.read_char()
        } else {
          break
        }
      }
      None => break
    }
  }
  
  let num_str = self.input.substring(start, self.position - 1)
  // Simple integer parsing (assumes valid input)
  let mut result : Int64 = 0L
  for i = 0; i < num_str.length(); i = i + 1 {
    let digit = (num_str[i].to_int() - '0'.to_int()).to_int64()
    result = result * 10L + digit
  }
  result
}

// Check if a character can start an identifier
fn is_identifier_start(ch : Char) -> Bool {
  (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch == '_'
}

// Check if a character can be part of an identifier
fn is_identifier_char(ch : Char) -> Bool {
  is_identifier_start(ch) || (ch >= '0' && ch <= '9') || ch == '-'
}

// Convert identifier to keyword token if applicable
fn identifier_to_token(ident : String) -> Token {
  match ident {
    // Keywords
    "interface" => Token::Interface
    "world" => Token::World
    "use" => Token::Use
    "type" => Token::Type
    "record" => Token::Record
    "enum" => Token::Enum
    "flags" => Token::Flags
    "variant" => Token::Variant
    "resource" => Token::Resource
    "func" => Token::Func
    "import" => Token::Import
    "export" => Token::Export
    "package" => Token::Package
    "constructor" => Token::Constructor
    "method" => Token::Method
    "static" => Token::Static
    
    // Types
    "bool" => Token::Bool
    "s8" => Token::S8
    "s16" => Token::S16
    "s32" => Token::S32
    "s64" => Token::S64
    "u8" => Token::U8
    "u16" => Token::U16
    "u32" => Token::U32
    "u64" => Token::U64
    "f32" => Token::F32
    "f64" => Token::F64
    "char" => Token::Char
    "string" => Token::String
    "list" => Token::List
    "option" => Token::Option
    "result" => Token::Result
    "tuple" => Token::Tuple
    "borrow" => Token::Borrow
    "own" => Token::Own
    
    // Default to identifier
    _ => Token::Identifier(ident)
  }
}

// Get the next token
pub fn next_token(self : Lexer) -> Token {
  self.skip_whitespace()
  
  match self.current_char {
    None => Token::Eof
    
    Some('\n') => {
      self.read_char()
      Token::Newline
    }
    
    Some('/') => {
      match self.peek_char() {
        Some('/') => {
          self.read_char() // consume second /
          self.skip_line_comment()
          self.next_token() // Get next token after comment
        }
        Some('*') => {
          self.read_char() // consume *
          self.skip_block_comment()
          self.next_token() // Get next token after comment
        }
        _ => {
          self.read_char()
          Token::Slash
        }
      }
    }
    
    Some('{') => {
      self.read_char()
      Token::LeftBrace
    }
    
    Some('}') => {
      self.read_char()
      Token::RightBrace
    }
    
    Some('(') => {
      self.read_char()
      Token::LeftParen
    }
    
    Some(')') => {
      self.read_char()
      Token::RightParen
    }
    
    Some('<') => {
      self.read_char()
      Token::LeftAngle
    }
    
    Some('>') => {
      self.read_char()
      Token::RightAngle
    }
    
    Some(',') => {
      self.read_char()
      Token::Comma
    }
    
    Some(':') => {
      self.read_char()
      Token::Colon
    }
    
    Some(';') => {
      self.read_char()
      Token::Semicolon
    }
    
    Some('.') => {
      self.read_char()
      Token::Dot
    }
    
    Some('*') => {
      self.read_char()
      Token::Star
    }
    
    Some('=') => {
      self.read_char()
      Token::Equals
    }
    
    Some('-') => {
      if self.peek_char() == Some('>') {
        self.read_char() // consume -
        self.read_char() // consume >
        Token::Arrow
      } else if let Some(ch) = self.peek_char() {
        if is_identifier_char(ch) {
          // Part of identifier like "my-function"
          let ident = self.read_identifier()
          identifier_to_token(ident)
        } else {
          self.read_char()
          Token::Identifier("-")
        }
      } else {
        self.read_char()
        Token::Identifier("-")
      }
    }
    
    Some('"') => {
      let str_lit = self.read_string_literal()
      Token::StringLiteral(str_lit)
    }
    
    Some(ch) => {
      if ch >= '0' && ch <= '9' {
        let num = self.read_integer_literal()
        Token::IntegerLiteral(num)
      } else if is_identifier_start(ch) {
        let ident = self.read_identifier()
        identifier_to_token(ident)
      } else {
        // Unknown character, skip it
        self.read_char()
        self.next_token()
      }
    }
  }
}

// Tokenize the entire input
pub fn tokenize(input : String) -> Array[Token] {
  let lexer = Lexer::new(input)
  let mut tokens : Array[Token] = []
  
  while true {
    let token = lexer.next_token()
    match token {
      Token::Eof => {
        tokens.push(token)
        break
      }
      Token::Newline => continue // Skip newlines
      _ => tokens.push(token)
    }
  }
  
  tokens
}