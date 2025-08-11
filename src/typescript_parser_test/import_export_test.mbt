// Tests for import and export declarations

test "parse default import" {
  let input = "import React from 'react'"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse()
  
  inspect(declarations.length(), content="1")
  
  match declarations[0] {
    Import(import_decl) => {
      inspect(import_decl.from, content="react")
      inspect(import_decl.specifiers.length(), content="1")
      match import_decl.specifiers[0] {
        Default(name) => inspect(name, content="React")
        _ => inspect(false, content="should be default import")
      }
    }
    _ => inspect(false, content="should be import")
  }
}

test "parse named imports" {
  let input = "import { useState, useEffect } from 'react'"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse()
  
  inspect(declarations.length(), content="1")
  
  match declarations[0] {
    Import(import_decl) => {
      inspect(import_decl.from, content="react")
      inspect(import_decl.specifiers.length(), content="2")
    }
    _ => inspect(false, content="should be import")
  }
}

test "parse import with alias" {
  let input = "import { Component as Comp } from 'react'"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse()
  
  inspect(declarations.length(), content="1")
  
  match declarations[0] {
    Import(import_decl) => {
      inspect(import_decl.specifiers.length(), content="1")
      match import_decl.specifiers[0] {
        Named(original, alias) => {
          inspect(original, content="Component")
          match alias {
            Some(a) => inspect(a, content="Comp")
            None => inspect(false, content="should have alias")
          }
        }
        _ => inspect(false, content="should be named import")
      }
    }
    _ => inspect(false, content="should be import")
  }
}

test "parse namespace import" {
  let input = "import * as React from 'react'"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse()
  
  inspect(declarations.length(), content="1")
  
  match declarations[0] {
    Import(import_decl) => {
      inspect(import_decl.specifiers.length(), content="1")
      match import_decl.specifiers[0] {
        Namespace(name) => inspect(name, content="React")
        _ => inspect(false, content="should be namespace import")
      }
    }
    _ => inspect(false, content="should be import")
  }
}

test "parse named export" {
  let input = "export { foo, bar as baz }"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse()
  
  inspect(declarations.length(), content="1")
  
  match declarations[0] {
    Export(export_decl) => {
      inspect(export_decl.named_exports.length(), content="2")
      inspect(export_decl.named_exports[0].local_name, content="foo")
      inspect(export_decl.named_exports[1].local_name, content="bar")
      match export_decl.named_exports[1].exported {
        Some(name) => inspect(name, content="baz")
        None => inspect(false, content="should have exported name")
      }
    }
    _ => inspect(false, content="should be export")
  }
}

test "parse re-export" {
  let input = "export { Component } from 'react'"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse()
  
  inspect(declarations.length(), content="1")
  
  match declarations[0] {
    Export(export_decl) => {
      inspect(export_decl.named_exports.length(), content="1")
      inspect(export_decl.named_exports[0].local_name, content="Component")
      match export_decl.from {
        Some(source) => inspect(source, content="react")
        None => inspect(false, content="should have from clause")
      }
    }
    _ => inspect(false, content="should be export")
  }
}

test "parse export all" {
  let input = "export * from 'utils'"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse()
  
  inspect(declarations.length(), content="1")
  
  match declarations[0] {
    Export(export_decl) => {
      match export_decl.from {
        Some(source) => inspect(source, content="utils")
        None => inspect(false, content="should have from clause")
      }
    }
    _ => inspect(false, content="should be export")
  }
}

test "parse mixed import" {
  let input = "import React, { useState } from 'react'"
  let lexer = Lexer::new(input)
  let parser = Parser::new(lexer)
  let declarations = parser.parse()
  
  inspect(declarations.length(), content="1")
  
  match declarations[0] {
    Import(import_decl) => {
      inspect(import_decl.specifiers.length(), content="2")
      match import_decl.specifiers[0] {
        Default(name) => inspect(name, content="React")
        _ => inspect(false, content="first should be default import")
      }
      match import_decl.specifiers[1] {
        Named(name, _) => inspect(name, content="useState")
        _ => inspect(false, content="second should be named import")
      }
    }
    _ => inspect(false, content="should be import")
  }
}