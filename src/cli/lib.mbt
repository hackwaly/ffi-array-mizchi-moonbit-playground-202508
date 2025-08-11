// CLI library for TypeScript parser
// This file exports functions to be called from JavaScript/TypeScript

// Parse TypeScript code and return AST as JSON
///|
pub fn parse_typescript(code : String) -> String {
  let lexer = @typescript_parser.Lexer::new(code)
  let parser = @typescript_parser.Parser::new(lexer)
  let declarations = parser.parse_typescript_file()

  // Convert AST to JSON string
  declarations_to_json(declarations)
}

// Generate FFI bindings from TypeScript code

///|
pub fn generate_ffi(code : String) -> String {
  let lexer = @typescript_parser.Lexer::new(code)
  let parser = @typescript_parser.Parser::new(lexer)
  let declarations = parser.parse_typescript_file()
  @typescript_parser.generate_ffi_code(declarations)
}

// Helper function to convert declarations to JSON

///|
fn declarations_to_json(declarations : Array[@typescript_parser.Declaration]) -> String {
  let result = StringBuilder::new()
  result.write_string("[")
  for i, decl in declarations {
    if i > 0 {
      result.write_string(",")
    }
    result.write_string(declaration_to_json(decl))
  }
  result.write_string("]")
  result.to_string()
}

// Convert a single declaration to JSON

///|
fn declaration_to_json(decl : @typescript_parser.Declaration) -> String {
  match decl {
    Interface(iface) => {
      let json = StringBuilder::new()
      json.write_string("{\"type\":\"interface\",\"name\":\"")
      json.write_string(iface.name)
      json.write_string("\",\"typeParams\":")
      json.write_string(string_array_to_json(iface.type_params))
      json.write_string(",\"members\":")
      json.write_string(members_to_json(iface.members))
      json.write_string("}")
      json.to_string()
    }
    TypeAlias(type_alias) => {
      let json = StringBuilder::new()
      json.write_string("{\"type\":\"typeAlias\",\"name\":\"")
      json.write_string(type_alias.name)
      json.write_string("\",\"typeParams\":")
      json.write_string(string_array_to_json(type_alias.type_params))
      json.write_string(",\"typeDefinition\":")
      json.write_string(type_to_json(type_alias.type_))
      json.write_string("}")
      json.to_string()
    }
    Function(func) => {
      let json = StringBuilder::new()
      json.write_string("{\"type\":\"function\",\"name\":\"")
      json.write_string(func.name)
      json.write_string("\",\"params\":")
      json.write_string(params_to_json(func.params))
      json.write_string(",\"returnType\":")
      json.write_string(type_to_json(func.return_type))
      json.write_string("}")
      json.to_string()
    }
    Class(cls) => {
      let json = StringBuilder::new()
      json.write_string("{\"type\":\"class\",\"name\":\"")
      json.write_string(cls.name)
      json.write_string("\",\"typeParams\":")
      json.write_string(string_array_to_json(cls.type_params))
      if cls.extends.is_some() {
        json.write_string(",\"extends\":\"")
        json.write_string(cls.extends.unwrap())
        json.write_string("\"")
      }
      json.write_string(",\"members\":")
      json.write_string(class_members_to_json(cls.members))
      json.write_string("}")
      json.to_string()
    }
    Export(export_decl) => {
      let json = StringBuilder::new()
      json.write_string("{\"type\":\"export\"")
      match export_decl.declaration {
        Some(inner_decl) => {
          json.write_string(",\"declaration\":")
          json.write_string(declaration_to_json(inner_decl))
        }
        None => ()
      }
      if export_decl.named_exports.length() > 0 {
        json.write_string(",\"namedExports\":")
        json.write_string(export_specifiers_to_json(export_decl.named_exports))
      }
      match export_decl.from {
        Some(source) => {
          json.write_string(",\"from\":\"")
          json.write_string(escape_json_string(source))
          json.write_string("\"")
        }
        None => ()
      }
      json.write_string("}")
      json.to_string()
    }
    Import(import_decl) => {
      let json = StringBuilder::new()
      json.write_string("{\"type\":\"import\",\"from\":\"")
      json.write_string(escape_json_string(import_decl.from))
      json.write_string("\",\"specifiers\":")
      json.write_string(import_specifiers_to_json(import_decl.specifiers))
      json.write_string("}")
      json.to_string()
    }
    _ => "{\"type\":\"unknown\"}"
  }
}

// Helper to convert string array to JSON

///|
fn string_array_to_json(arr : Array[String]) -> String {
  let result = StringBuilder::new()
  result.write_string("[")
  for i, s in arr {
    if i > 0 {
      result.write_string(",")
    }
    result.write_string("\"")
    result.write_string(escape_json_string(s))
    result.write_string("\"")
  }
  result.write_string("]")
  result.to_string()
}

// Convert interface members to JSON

///|
fn members_to_json(members : Array[@typescript_parser.InterfaceMember]) -> String {
  let result = StringBuilder::new()
  result.write_string("[")
  for i, member in members {
    if i > 0 {
      result.write_string(",")
    }
    match member {
      Property(prop) => {
        result.write_string("{\"type\":\"property\",\"name\":\"")
        result.write_string(prop.name)
        result.write_string("\",\"optional\":")
        result.write_string(if prop.optional { "true" } else { "false" })
        result.write_string(",\"valueType\":")
        result.write_string(type_to_json(prop.type_))
        result.write_string("}")
      }
      _ => result.write_string("{\"type\":\"unknown\"}")
    }
  }
  result.write_string("]")
  result.to_string()
}

// Convert class members to JSON

///|
fn class_members_to_json(members : Array[@typescript_parser.ClassMember]) -> String {
  let result = StringBuilder::new()
  result.write_string("[")
  for i, member in members {
    if i > 0 {
      result.write_string(",")
    }
    match member {
      ClassProperty(prop) => {
        result.write_string("{\"type\":\"property\",\"name\":\"")
        result.write_string(prop.name)
        result.write_string("\",\"visibility\":\"")
        result.write_string(visibility_to_string(prop.visibility))
        result.write_string("\",\"static\":")
        result.write_string(if prop.is_static { "true" } else { "false" })
        result.write_string(",\"valueType\":")
        result.write_string(type_to_json(prop.type_))
        result.write_string("}")
      }
      ClassMethod(method) => {
        result.write_string("{\"type\":\"method\",\"name\":\"")
        result.write_string(method.name)
        result.write_string("\",\"visibility\":\"")
        result.write_string(visibility_to_string(method.visibility))
        result.write_string("\",\"static\":")
        result.write_string(if method.is_static { "true" } else { "false" })
        result.write_string(",\"params\":")
        result.write_string(params_to_json(method.params))
        result.write_string(",\"returnType\":")
        result.write_string(type_to_json(method.return_type))
        result.write_string("}")
      }
      ClassConstructor(ctor) => {
        result.write_string("{\"type\":\"constructor\",\"params\":")
        result.write_string(params_to_json(ctor.params))
        result.write_string("}")
      }
    }
  }
  result.write_string("]")
  result.to_string()
}

// Convert visibility to string

///|
fn visibility_to_string(vis : @typescript_parser.Visibility) -> String {
  match vis {
    Public => "public"
    Private => "private"
    Protected => "protected"
  }
}

// Convert parameters to JSON

///|
fn params_to_json(params : Array[@typescript_parser.Parameter]) -> String {
  let result = StringBuilder::new()
  result.write_string("[")
  for i, param in params {
    if i > 0 {
      result.write_string(",")
    }
    result.write_string("{\"name\":\"")
    result.write_string(param.name)
    result.write_string("\",\"type\":")
    result.write_string(type_to_json(param.type_))
    result.write_string(",\"optional\":")
    result.write_string(if param.optional { "true" } else { "false" })
    result.write_string(",\"rest\":")
    result.write_string(if param.rest { "true" } else { "false" })
    result.write_string("}")
  }
  result.write_string("]")
  result.to_string()
}

// Convert Type to JSON

///|
fn type_to_json(typ : @typescript_parser.Type) -> String {
  match typ {
    String => "\"string\""
    Number => "\"number\""
    Boolean => "\"boolean\""
    Void => "\"void\""
    Any => "\"any\""
    Unknown => "\"unknown\""
    Never => "\"never\""
    Null => "\"null\""
    Undefined => "\"undefined\""
    Array(elem) => {
      let result = StringBuilder::new()
      result.write_string("{\"type\":\"array\",\"elementType\":")
      result.write_string(type_to_json(elem))
      result.write_string("}")
      result.to_string()
    }
    Union(types) => {
      let result = StringBuilder::new()
      result.write_string("{\"type\":\"union\",\"types\":[")
      for i, t in types {
        if i > 0 {
          result.write_string(",")
        }
        result.write_string(type_to_json(t))
      }
      result.write_string("]}")
      result.to_string()
    }
    TypeReference(name, type_args) => {
      let result = StringBuilder::new()
      result.write_string("{\"type\":\"reference\",\"name\":\"")
      result.write_string(name)
      result.write_string("\"")
      if type_args.length() > 0 {
        result.write_string(",\"typeArguments\":[")
        for i, arg in type_args {
          if i > 0 {
            result.write_string(",")
          }
          result.write_string(type_to_json(arg))
        }
        result.write_string("]")
      }
      result.write_string("}")
      result.to_string()
    }
    Object(props) => {
      let result = StringBuilder::new()
      result.write_string("{\"type\":\"object\",\"properties\":{")
      let mut first = true
      for key, value in props {
        if not(first) {
          result.write_string(",")
        }
        first = false
        result.write_string("\"")
        result.write_string(escape_json_string(key))
        result.write_string("\":")
        result.write_string(type_to_json(value))
      }
      result.write_string("}}")
      result.to_string()
    }
    Function(func_type) => {
      let result = StringBuilder::new()
      result.write_string("{\"type\":\"function\",\"params\":")
      result.write_string(params_to_json(func_type.params))
      result.write_string(",\"returnType\":")
      result.write_string(type_to_json(func_type.return_type))
      result.write_string("}")
      result.to_string()
    }
    _ => "\"unknown\""
  }
}

// Convert export specifiers to JSON

///|
fn export_specifiers_to_json(
  specifiers : Array[@typescript_parser.ExportSpecifier],
) -> String {
  let result = StringBuilder::new()
  result.write_string("[")
  for i, spec in specifiers {
    if i > 0 {
      result.write_string(",")
    }
    result.write_string("{\"local\":\"")
    result.write_string(escape_json_string(spec.local_name))
    result.write_string("\"")
    match spec.exported {
      Some(name) => {
        result.write_string(",\"exported\":\"")
        result.write_string(escape_json_string(name))
        result.write_string("\"")
      }
      None => ()
    }
    result.write_string("}")
  }
  result.write_string("]")
  result.to_string()
}

// Convert import specifiers to JSON

///|
fn import_specifiers_to_json(
  specifiers : Array[@typescript_parser.ImportSpecifier],
) -> String {
  let result = StringBuilder::new()
  result.write_string("[")
  for i, spec in specifiers {
    if i > 0 {
      result.write_string(",")
    }
    match spec {
      Default(name) => {
        result.write_string("{\"type\":\"default\",\"name\":\"")
        result.write_string(escape_json_string(name))
        result.write_string("\"}")
      }
      Named(local, imported) => {
        result.write_string("{\"type\":\"named\",\"local\":\"")
        result.write_string(escape_json_string(local))
        result.write_string("\"")
        match imported {
          Some(name) => {
            result.write_string(",\"imported\":\"")
            result.write_string(escape_json_string(name))
            result.write_string("\"")
          }
          None => ()
        }
        result.write_string("}")
      }
      Namespace(name) => {
        result.write_string("{\"type\":\"namespace\",\"name\":\"")
        result.write_string(escape_json_string(name))
        result.write_string("\"}")
      }
    }
  }
  result.write_string("]")
  result.to_string()
}

// Escape JSON string

///|
fn escape_json_string(s : String) -> String {
  let result = StringBuilder::new()
  for c in s {
    match c {
      '"' => result.write_string("\\\"")
      '\\' => result.write_string("\\\\")
      '\n' => result.write_string("\\n")
      '\r' => result.write_string("\\r")
      '\t' => result.write_string("\\t")
      _ => result.write_char(c)
    }
  }
  result.to_string()
}
