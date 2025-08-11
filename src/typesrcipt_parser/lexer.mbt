pub enum Token {
  // Literals and identifiers
  Identifier(String)
  StringLiteral(String)  // 文字列リテラル
  NumberLiteral(String)  // 数値リテラル
  
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
  Constructor
  Extends
  Public
  Private
  Protected
  Static
  Readonly
  Async     // async キーワード
  Implements // implements キーワード
  From      // from キーワード
  As        // as キーワード
  Declare   // declare キーワード
  Default   // default キーワード
  
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
  LessThan      // <
  GreaterThan   // >
  Star          // *
  DotDotDot     // ...
  
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
        } else if ch == '/' {
          // コメントの可能性をチェック
          let next_pos = self.position + 1
          if next_pos < self.input.length() {
            let next_ch = Int::unsafe_to_char(self.input[next_pos])
            if next_ch == '/' {
              // 行コメント
              self.skip_line_comment()
            } else if next_ch == '*' {
              // ブロックコメント
              self.skip_block_comment()
            } else {
              break
            }
          } else {
            break
          }
        } else {
          break
        }
      }
      None => break
    }
  }
}

fn skip_line_comment(self : Lexer) -> Unit {
  // // をスキップ
  self.advance()
  self.advance()
  
  // 改行まで読み飛ばす
  while true {
    match self.current_char() {
      Some(ch) => {
        if ch == '\n' {
          self.advance()
          break
        }
        self.advance()
      }
      None => break
    }
  }
}

fn skip_block_comment(self : Lexer) -> Unit {
  // /* をスキップ
  self.advance()
  self.advance()
  
  // */ まで読み飛ばす
  while true {
    match self.current_char() {
      Some(ch) => {
        if ch == '*' {
          let next_pos = self.position + 1
          if next_pos < self.input.length() {
            let next_ch = Int::unsafe_to_char(self.input[next_pos])
            if next_ch == '/' {
              self.advance()
              self.advance()
              break
            }
          }
        }
        self.advance()
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
        if is_letter(ch) || is_digit(ch) || ch == '_' || ch == '$' {
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

fn read_string(self : Lexer, quote : Char) -> String {
  let start = self.position
  self.advance() // Skip opening quote
  
  while true {
    match self.current_char() {
      Some(ch) => {
        if ch == quote {
          let result = self.input.substring(start=start + 1, end=self.position)
          self.advance() // Skip closing quote
          return result
        } else if ch == '\\' {
          // エスケープシーケンスをスキップ
          self.advance()
          if self.position < self.input.length() {
            self.advance()
          }
        } else {
          self.advance()
        }
      }
      None => break
    }
  }
  self.input.substring(start=start + 1, end=self.position)
}

fn read_template_literal(self : Lexer) -> String {
  let start = self.position
  self.advance() // Skip opening backtick
  
  while true {
    match self.current_char() {
      Some(ch) => {
        if ch == '`' {
          let result = self.input.substring(start=start + 1, end=self.position)
          self.advance() // Skip closing backtick
          return result
        } else if ch == '\\' {
          // エスケープシーケンスをスキップ
          self.advance()
          if self.position < self.input.length() {
            self.advance()
          }
        } else if ch == '$' {
          // テンプレート式の可能性をチェック
          let next_pos = self.position + 1
          if next_pos < self.input.length() {
            let next_ch = Int::unsafe_to_char(self.input[next_pos])
            if next_ch == '{' {
              // ${...} をスキップ
              self.skip_template_expression()
            } else {
              self.advance()
            }
          } else {
            self.advance()
          }
        } else {
          self.advance()
        }
      }
      None => break
    }
  }
  self.input.substring(start=start + 1, end=self.position)
}

fn skip_template_expression(self : Lexer) -> Unit {
  // ${ をスキップ
  self.advance()
  self.advance()
  
  let mut brace_count = 1
  while brace_count > 0 {
    match self.current_char() {
      Some(ch) => {
        if ch == '{' {
          brace_count += 1
        } else if ch == '}' {
          brace_count -= 1
        } else if ch == '"' || ch == '\'' {
          let _ = self.read_string(ch)
          continue
        } else if ch == '`' {
          let _ = self.read_template_literal()
          continue
        }
        self.advance()
      }
      None => break
    }
  }
}

fn read_number(self : Lexer) -> String {
  let start = self.position
  
  // 整数部分
  while true {
    match self.current_char() {
      Some(ch) => {
        if is_digit(ch) {
          self.advance()
        } else {
          break
        }
      }
      None => break
    }
  }
  
  // 小数点と小数部分
  match self.current_char() {
    Some('.') => {
      let next_pos = self.position + 1
      if next_pos < self.input.length() {
        let next_ch = Int::unsafe_to_char(self.input[next_pos])
        if is_digit(next_ch) {
          self.advance() // Skip '.'
          while true {
            match self.current_char() {
              Some(ch) => {
                if is_digit(ch) {
                  self.advance()
                } else {
                  break
                }
              }
              None => break
            }
          }
        }
      }
    }
    _ => ()
  }
  
  // 指数部分
  match self.current_char() {
    Some(ch) if ch == 'e' || ch == 'E' => {
      self.advance()
      match self.current_char() {
        Some(sign) if sign == '+' || sign == '-' => self.advance()
        _ => ()
      }
      while true {
        match self.current_char() {
          Some(ch) => {
            if is_digit(ch) {
              self.advance()
            } else {
              break
            }
          }
          None => break
        }
      }
    }
    _ => ()
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
    "constructor" => Token::Constructor
    "extends" => Token::Extends
    "implements" => Token::Implements
    "public" => Token::Public
    "private" => Token::Private
    "protected" => Token::Protected
    "static" => Token::Static
    "readonly" => Token::Readonly
    "async" => Token::Async
    "from" => Token::From
    "as" => Token::As
    "declare" => Token::Declare
    "default" => Token::Default
    _ => Token::Identifier(ident)
  }
}

pub fn Lexer::next_token(self : Lexer) -> Token {
  self.skip_whitespace()
  
  match self.current_char() {
    None => Token::Eof
    Some(ch) => {
      if is_letter(ch) || ch == '_' || ch == '$' {
        let ident = self.read_identifier()
        lookup_keyword(ident)
      } else if is_digit(ch) {
        let num = self.read_number()
        Token::NumberLiteral(num)
      } else if ch == '"' || ch == '\'' {
        let str = self.read_string(ch)
        Token::StringLiteral(str)
      } else if ch == '`' {
        let str = self.read_template_literal()
        Token::StringLiteral(str)
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
          '.' => {
            // Check for DotDotDot (...)
            let next1 = if self.position + 1 < self.input.length() { 
              Some(Int::unsafe_to_char(self.input[self.position + 1])) 
            } else { 
              None 
            }
            let next2 = if self.position + 2 < self.input.length() { 
              Some(Int::unsafe_to_char(self.input[self.position + 2])) 
            } else { 
              None 
            }
            match (next1, next2) {
              (Some('.'), Some('.')) => {
                self.advance() // skip first .
                self.advance() // skip second .
                self.advance() // skip third .
                return Token::DotDotDot
              }
              _ => Token::Dot
            }
          }
          '?' => Token::Question
          '|' => Token::Pipe
          '&' => Token::Ampersand
          '<' => Token::LessThan
          '>' => Token::GreaterThan
          '*' => Token::Star
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