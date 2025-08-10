// JSON Schema to MoonBit code generator

pub struct CodegenOptions {
  derives : Array[String]  // e.g., ["Show", "Eq", "ToJson"]
  use_pub : Bool           // Whether to generate public types
  indent : String          // Indentation string (default "  ")
}

pub fn CodegenOptions::default() -> CodegenOptions {
  CodegenOptions::{
    derives: [],
    use_pub: true,
    indent: "  "
  }
}

pub fn CodegenOptions::with_derives(derives : Array[String]) -> CodegenOptions {
  CodegenOptions::{
    derives,
    use_pub: true,
    indent: "  "
  }
}

// Generate MoonBit code from a JSON Schema
pub fn generate_moonbit_code(schema : Schema, name : String, options : CodegenOptions) -> String {
  let code = StringBuilder::new(size_hint=1000)
  generate_type(schema, name, options, code, 0)
  code.to_string()
}

fn generate_type(schema : Schema, name : String, options : CodegenOptions, code : StringBuilder, depth : Int) -> Unit {
  match schema {
    Schema::Object(constraints) => {
      generate_struct(name, constraints, options, code, depth)
    }
    Schema::Array(constraints) => {
      // Generate type alias for array
      let visibility = if options.use_pub { "pub " } else { "" }
      let type_alias = match constraints.items {
        Some(item_schema) => {
          let item_type = get_type_name(item_schema)
          "\{visibility}type \{name} = Array[\{item_type}]"
        }
        None => "\{visibility}type \{name} = Array[Json]"
      }
      code.write_string(type_alias)
      code.write_string("\n")
    }
    Schema::String(_) => {
      // For simple string, generate type alias
      let visibility = if options.use_pub { "pub " } else { "" }
      code.write_string("\{visibility}type \{name} = String\n")
    }
    Schema::Number(_) | Schema::Integer(_) => {
      // For numbers, generate type alias
      let visibility = if options.use_pub { "pub " } else { "" }
      let num_type = match schema {
        Schema::Integer(_) => "Int"
        _ => "Double"
      }
      code.write_string("\{visibility}type \{name} = \{num_type}\n")
    }
    Schema::Boolean => {
      let visibility = if options.use_pub { "pub " } else { "" }
      code.write_string("\{visibility}type \{name} = Bool\n")
    }
    Schema::EnumValues(values) => {
      generate_enum_from_values(name, values, options, code, depth)
    }
    Schema::AnyOfSchemas(schemas) | Schema::OneOfSchemas(schemas) => {
      generate_union_type(name, schemas, options, code, depth)
    }
    _ => {
      // For other types, generate a generic Json type alias
      let visibility = if options.use_pub { "pub " } else { "" }
      code.write_string("\{visibility}type \{name} = Json\n")
    }
  }
}

fn generate_struct(
  name : String,
  constraints : ObjectConstraints,
  options : CodegenOptions,
  code : StringBuilder,
  depth : Int
) -> Unit {
  let indent = repeat_string(options.indent, depth)
  let visibility = if options.use_pub { "pub " } else { "" }
  
  // Generate struct header
  code.write_string("\{indent}\{visibility}struct \{name} {\n")
  
  // Generate fields
  match constraints.properties {
    Some(props) => {
      let required_set = match constraints.required {
        Some(req) => {
          let set : Map[String, Bool] = Map::new()
          for i = 0; i < req.length(); i = i + 1 {
            set.set(req[i], true)
          }
          set
        }
        None => Map::new()
      }
      
      props.each(fn(prop_name, prop_schema) {
        let field_indent = repeat_string(options.indent, depth + 1)
        let field_type = get_type_name(prop_schema)
        let is_required = required_set.contains(prop_name)
        let moonbit_name = to_moonbit_identifier(prop_name)
        
        if is_required {
          code.write_string("\{field_indent}\{moonbit_name} : \{field_type}\n")
        } else {
          code.write_string("\{field_indent}\{moonbit_name} : \{field_type}?\n")
        }
      })
    }
    None => ()
  }
  
  // Close struct
  code.write_string("\{indent}}")
  
  // Add derives if specified
  if options.derives.length() > 0 {
    code.write_string(" derive(")
    for i = 0; i < options.derives.length(); i = i + 1 {
      if i > 0 {
        code.write_string(", ")
      }
      code.write_string(options.derives[i])
    }
    code.write_string(")")
  }
  
  code.write_string("\n")
  
  // Generate constructor function
  generate_constructor(name, constraints, options, code, depth)
}

fn generate_constructor(
  name : String,
  constraints : ObjectConstraints,
  options : CodegenOptions,
  code : StringBuilder,
  depth : Int
) -> Unit {
  let indent = repeat_string(options.indent, depth)
  let visibility = if options.use_pub { "pub " } else { "" }
  
  code.write_string("\n")
  code.write_string("\{indent}\{visibility}fn \{name}::new(\n")
  
  // Generate parameters
  match constraints.properties {
    Some(props) => {
      let required_set = match constraints.required {
        Some(req) => {
          let set : Map[String, Bool] = Map::new()
          for i = 0; i < req.length(); i = i + 1 {
            set.set(req[i], true)
          }
          set
        }
        None => Map::new()
      }
      
      let mut first = true
      props.each(fn(prop_name, prop_schema) {
        if required_set.contains(prop_name) {
          if not(first) {
            code.write_string(",\n")
          } else {
            first = false
          }
          let param_indent = repeat_string(options.indent, depth + 1)
          let field_type = get_type_name(prop_schema)
          let moonbit_name = to_moonbit_identifier(prop_name)
          code.write_string("\{param_indent}\{moonbit_name} : \{field_type}")
        }
      })
      
      // Add optional parameters
      props.each(fn(prop_name, prop_schema) {
        if not(required_set.contains(prop_name)) {
          if not(first) {
            code.write_string(",\n")
          } else {
            first = false
          }
          let param_indent = repeat_string(options.indent, depth + 1)
          let field_type = get_type_name(prop_schema)
          let moonbit_name = to_moonbit_identifier(prop_name)
          code.write_string("\{param_indent}\{moonbit_name}~ : \{field_type}? = None")
        }
      })
    }
    None => ()
  }
  
  code.write_string("\n\{indent}) -> \{name} {\n")
  code.write_string("\{indent}  \{name}::{\n")
  
  // Generate field assignments
  match constraints.properties {
    Some(props) => {
      props.each(fn(prop_name, _prop_schema) {
        let field_indent = repeat_string(options.indent, depth + 2)
        let moonbit_name = to_moonbit_identifier(prop_name)
        code.write_string("\{field_indent}\{moonbit_name},\n")
      })
    }
    None => ()
  }
  
  code.write_string("\{indent}  }\n")
  code.write_string("\{indent}}\n")
}

fn generate_enum_from_values(
  name : String,
  values : Array[Json],
  options : CodegenOptions,
  code : StringBuilder,
  depth : Int
) -> Unit {
  let indent = repeat_string(options.indent, depth)
  let visibility = if options.use_pub { "pub " } else { "" }
  
  // Check if all values are strings
  let mut all_strings = true
  for i = 0; i < values.length(); i = i + 1 {
    match values[i] {
      @json.String(_) => ()
      _ => all_strings = false
    }
  }
  
  if all_strings {
    // Generate enum for string values
    code.write_string("\{indent}\{visibility}enum \{name} {\n")
    
    for i = 0; i < values.length(); i = i + 1 {
      match values[i] {
        @json.String(s) => {
          let variant_name = to_pascal_case(s)
          let variant_indent = repeat_string(options.indent, depth + 1)
          code.write_string("\{variant_indent}\{variant_name}\n")
        }
        _ => ()
      }
    }
    
    code.write_string("\{indent}}")
    
    // Add derives
    if options.derives.length() > 0 {
      code.write_string(" derive(")
      for i = 0; i < options.derives.length(); i = i + 1 {
        if i > 0 {
          code.write_string(", ")
        }
        code.write_string(options.derives[i])
      }
      code.write_string(")")
    }
    
    code.write_string("\n")
    
    // Generate from_string and to_string functions
    generate_enum_conversions(name, values, options, code, depth)
  } else {
    // For mixed types, generate a type alias
    let visibility = if options.use_pub { "pub " } else { "" }
    code.write_string("\{visibility}type \{name} = Json\n")
  }
}

fn generate_enum_conversions(
  name : String,
  values : Array[Json],
  options : CodegenOptions,
  code : StringBuilder,
  depth : Int
) -> Unit {
  let indent = repeat_string(options.indent, depth)
  let visibility = if options.use_pub { "pub " } else { "" }
  
  // Generate from_string function
  code.write_string("\n")
  code.write_string("\{indent}\{visibility}fn \{name}::from_string(s : String) -> \{name}? {\n")
  code.write_string("\{indent}  match s {\n")
  
  for i = 0; i < values.length(); i = i + 1 {
    match values[i] {
      @json.String(s) => {
        let variant_name = to_pascal_case(s)
        code.write_string("\{indent}    \"\{s}\" => Some(\{variant_name})\n")
      }
      _ => ()
    }
  }
  
  code.write_string("\{indent}    _ => None\n")
  code.write_string("\{indent}  }\n")
  code.write_string("\{indent}}\n")
  
  // Generate to_string function
  code.write_string("\n")
  code.write_string("\{indent}\{visibility}fn to_string(self : \{name}) -> String {\n")
  code.write_string("\{indent}  match self {\n")
  
  for i = 0; i < values.length(); i = i + 1 {
    match values[i] {
      @json.String(s) => {
        let variant_name = to_pascal_case(s)
        code.write_string("\{indent}    \{variant_name} => \"\{s}\"\n")
      }
      _ => ()
    }
  }
  
  code.write_string("\{indent}  }\n")
  code.write_string("\{indent}}\n")
}

fn generate_union_type(
  name : String,
  schemas : Array[Schema],
  options : CodegenOptions,
  code : StringBuilder,
  depth : Int
) -> Unit {
  let indent = repeat_string(options.indent, depth)
  let visibility = if options.use_pub { "pub " } else { "" }
  
  // Generate enum for union types
  code.write_string("\{indent}\{visibility}enum \{name} {\n")
  
  for i = 0; i < schemas.length(); i = i + 1 {
    let variant_indent = repeat_string(options.indent, depth + 1)
    let variant_name = "Variant\{i + 1}"
    let variant_type = get_type_name(schemas[i])
    code.write_string("\{variant_indent}\{variant_name}(\{variant_type})\n")
  }
  
  code.write_string("\{indent}}")
  
  // Add derives
  if options.derives.length() > 0 {
    code.write_string(" derive(")
    for i = 0; i < options.derives.length(); i = i + 1 {
      if i > 0 {
        code.write_string(", ")
      }
      code.write_string(options.derives[i])
    }
    code.write_string(")")
  }
  
  code.write_string("\n")
}

fn get_type_name(schema : Schema) -> String {
  match schema {
    Schema::Null => "Unit?"
    Schema::Boolean => "Bool"
    Schema::String(_) => "String"
    Schema::Number(_) => "Double"
    Schema::Integer(_) => "Int"
    Schema::Array(constraints) => {
      match constraints.items {
        Some(item_schema) => "Array[\{get_type_name(item_schema)}]"
        None => "Array[Json]"
      }
    }
    Schema::Object(_) => "Map[String, Json]"
    _ => "Json"
  }
}

pub fn to_moonbit_identifier(name : String) -> String {
  // Convert kebab-case or camelCase to snake_case
  let result = StringBuilder::new(size_hint=name.length())
  let chars = name.to_array()
  
  for i = 0; i < chars.length(); i = i + 1 {
    let c = chars[i]
    if c == '-' {
      result.write_char('_')
    } else if c >= 'A' && c <= 'Z' {
      if i > 0 {
        result.write_char('_')
      }
      // Convert uppercase to lowercase
      let lower_c = (c.to_int() + 32) |> Int::to_char() |> Option::unwrap_or(c)
      result.write_char(lower_c)
    } else {
      result.write_char(c)
    }
  }
  
  result.to_string()
}

pub fn to_pascal_case(name : String) -> String {
  let result = StringBuilder::new(size_hint=name.length())
  let chars = name.to_array()
  let mut capitalize_next = true
  
  for i = 0; i < chars.length(); i = i + 1 {
    let c = chars[i]
    if c == '-' || c == '_' || c == ' ' {
      capitalize_next = true
    } else if capitalize_next {
      // Convert lowercase to uppercase if needed
      let upper_c = if c >= 'a' && c <= 'z' {
        (c.to_int() - 32) |> Int::to_char() |> Option::unwrap_or(c)
      } else {
        c
      }
      result.write_char(upper_c)
      capitalize_next = false
    } else {
      result.write_char(c)
    }
  }
  
  result.to_string()
}

fn repeat_string(s : String, count : Int) -> String {
  let result = StringBuilder::new(size_hint=s.length() * count)
  for i = 0; i < count; i = i + 1 {
    result.write_string(s)
  }
  result.to_string()
}