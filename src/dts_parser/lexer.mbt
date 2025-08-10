pub enum Token {
  // Literals and identifiers
  Identifier(String)
  
  // Keywords
  Interface
  Function
  Const
  Let
  Var
  Export
  Import
  Type
  Class
  Enum
  Namespace
  Module
  
  // Symbols
  LeftBrace     // {
  RightBrace    // }
  LeftParen     // (
  RightParen    // )
  LeftBracket   // [
  RightBracket  // ]
  Semicolon     // ;
  Colon         // :
  Comma         // ,
  Dot           // .
  Arrow         // =>
  Equals        // =
  Question      // ?
  Pipe          // |
  Ampersand     // &
  
  // Special
  Eof
} derive(Eq, Show)

pub struct Lexer {
  input : String
  mut position : Int
}

pub fn Lexer::new(input : String) -> Lexer {
  { input, position: 0 }
}

fn current_char(self : Lexer) -> Option[Char] {
  if self.position >= self.input.length() {
    None
  } else {
    Some(Int::unsafe_to_char(self.input[self.position]))
  }
}

fn advance(self : Lexer) -> Unit {
  if self.position < self.input.length() {
    self.position += 1
  }
}

fn skip_whitespace(self : Lexer) -> Unit {
  while true {
    match self.current_char() {
      Some(ch) => {
        if ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n' {
          self.advance()
        } else {
          break
        }
      }
      None => break
    }
  }
}

fn read_identifier(self : Lexer) -> String {
  let start = self.position
  
  while true {
    match self.current_char() {
      Some(ch) => {
        if is_letter(ch) || is_digit(ch) || ch == '_' {
          self.advance()
        } else {
          break
        }
      }
      None => break
    }
  }
  self.input.substring(start=start, end=self.position)
}

fn is_letter(ch : Char) -> Bool {
  (ch.to_int() >= 'a'.to_int() && ch.to_int() <= 'z'.to_int()) || 
  (ch.to_int() >= 'A'.to_int() && ch.to_int() <= 'Z'.to_int())
}

fn is_digit(ch : Char) -> Bool {
  ch.to_int() >= '0'.to_int() && ch.to_int() <= '9'.to_int()
}

fn lookup_keyword(ident : String) -> Token {
  match ident {
    "interface" => Token::Interface
    "function" => Token::Function
    "const" => Token::Const
    "let" => Token::Let
    "var" => Token::Var
    "export" => Token::Export
    "import" => Token::Import
    "type" => Token::Type
    "class" => Token::Class
    "enum" => Token::Enum
    "namespace" => Token::Namespace
    "module" => Token::Module
    _ => Token::Identifier(ident)
  }
}

pub fn Lexer::next_token(self : Lexer) -> Token {
  self.skip_whitespace()
  
  match self.current_char() {
    None => Token::Eof
    Some(ch) => {
      if is_letter(ch) || ch == '_' {
        let ident = self.read_identifier()
        lookup_keyword(ident)
      } else {
        let token = match ch {
          '{' => Token::LeftBrace
          '}' => Token::RightBrace
          '(' => Token::LeftParen
          ')' => Token::RightParen
          '[' => Token::LeftBracket
          ']' => Token::RightBracket
          ';' => Token::Semicolon
          ':' => Token::Colon
          ',' => Token::Comma
          '.' => Token::Dot
          '?' => Token::Question
          '|' => Token::Pipe
          '&' => Token::Ampersand
          '=' => {
            self.advance()
            match self.current_char() {
              Some('>') => {
                self.advance()
                return Token::Arrow
              }
              _ => return Token::Equals
            }
          }
          _ => {
            self.advance()
            return self.next_token()
          }
        }
        self.advance()
        token
      }
    }
  }
}