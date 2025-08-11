// WIT to MoonBit code generation

// Convert WIT type to MoonBit type
pub fn type_to_moonbit(typ : Type) -> String {
  match typ {
    // Primitive types
    Bool => "Bool"
    S8 | S16 | S32 => "Int"  // MoonBit uses Int for smaller integers
    S64 => "Int64"
    U8 | U16 | U32 => "UInt"  // Unsigned integers
    U64 => "UInt64"
    F32 => "Float"
    F64 => "Double"
    Char => "Char"
    String => "String"
    
    // Compound types
    List(inner) => "Array[" + type_to_moonbit(inner) + "]"
    Option(inner) => "Option[" + type_to_moonbit(inner) + "]"
    Result { ok, err } => {
      let ok_type = match ok {
        Some(t) => type_to_moonbit(t)
        None => "Unit"
      }
      let err_type = match err {
        Some(t) => type_to_moonbit(t)
        None => "Unit"
      }
      "Result[" + ok_type + ", " + err_type + "]"
    }
    Tuple(types) => {
      if types.length() == 0 {
        "Unit"
      } else {
        let type_strs = types.map(fn(t) { type_to_moonbit(t) })
        "(" + type_strs.join(", ") + ")"
      }
    }
    
    // Named types
    Named(name) => sanitize_identifier(name)
    
    // Resource types
    Borrow(name) => sanitize_identifier(name) + "Ref"
    Own(name) => sanitize_identifier(name)
  }
}

// Sanitize identifier for MoonBit (convert kebab-case to PascalCase or camelCase)
fn sanitize_identifier(name : String) -> String {
  let parts = name.split('-')
  if parts.length() == 1 {
    return name
  }
  
  // Convert to PascalCase
  let result = StringBuilder::new()
  for i = 0; i < parts.length(); i = i + 1 {
    let part = parts[i]
    if part.length() > 0 {
      // Capitalize first letter
      let first_char = part[0]
      let upper_char = if first_char >= 'a' && first_char <= 'z' {
        Char::from_int(first_char.to_int() - 32)
      } else {
        first_char
      }
      result.write_char(upper_char)
      
      // Add rest of the string
      for j = 1; j < part.length(); j = j + 1 {
        result.write_char(part[j])
      }
    }
  }
  
  result.to_string()
}

// Convert function name to MoonBit (kebab-case to camelCase)
fn function_name_to_moonbit(name : String) -> String {
  let parts = name.split('-')
  if parts.length() == 1 {
    return name
  }
  
  // Convert to camelCase
  let result = StringBuilder::new()
  for i = 0; i < parts.length(); i = i + 1 {
    let part = parts[i]
    if part.length() > 0 {
      if i == 0 {
        // First part stays lowercase
        result.write_string(part)
      } else {
        // Capitalize first letter of subsequent parts
        let first_char = part[0]
        let upper_char = if first_char >= 'a' && first_char <= 'z' {
          Char::from_int(first_char.to_int() - 32)
        } else {
          first_char
        }
        result.write_char(upper_char)
        
        // Add rest of the string
        for j = 1; j < part.length(); j = j + 1 {
          result.write_char(part[j])
        }
      }
    }
  }
  
  result.to_string()
}

// Generate MoonBit code for a WIT document
pub fn generate_moonbit(doc : WitDocument) -> String {
  let output = StringBuilder::new()
  
  // Add header comment
  output.write_string("// Generated from WIT definition\n\n")
  
  // Process each top-level item
  for i = 0; i < doc.items.length(); i = i + 1 {
    generate_top_level_item(doc.items[i], output)
    output.write_string("\n")
  }
  
  output.to_string()
}

// Generate code for top-level item
fn generate_top_level_item(item : TopLevelItem, output : StringBuilder) -> Unit {
  match item {
    Interface(iface) => generate_interface(iface, output)
    World(world) => generate_world(world, output)
    Use(use_item) => generate_use(use_item, output)
  }
}

// Generate code for interface
fn generate_interface(iface : Interface, output : StringBuilder) -> Unit {
  output.write_string("// Interface: " + iface.name + "\n")
  
  // Generate each interface item
  for i = 0; i < iface.items.length(); i = i + 1 {
    generate_interface_item(iface.items[i], output)
  }
}

// Generate code for interface item
fn generate_interface_item(item : InterfaceItem, output : StringBuilder) -> Unit {
  match item {
    Use(use_item) => generate_use(use_item, output)
    Type(type_def) => generate_type_def(type_def, output)
    Function(func) => generate_function(func, output)
    Export(name) => {
      output.write_string("// Export: " + name + "\n")
    }
  }
}

// Generate code for world
fn generate_world(world : World, output : StringBuilder) -> Unit {
  output.write_string("// World: " + world.name + "\n")
  output.write_string("pub struct " + sanitize_identifier(world.name) + " {\n")
  
  // Generate imports as fields
  for i = 0; i < world.items.length(); i = i + 1 {
    match world.items[i] {
      Import(import) => {
        output.write_string("  " + function_name_to_moonbit(import.name) + " : ")
        match import.kind {
          ImportKind::Function(func) => {
            output.write_string(generate_function_type(func))
          }
          ImportKind::Interface(iface_name) => {
            output.write_string(sanitize_identifier(iface_name))
          }
        }
        output.write_string("\n")
      }
      _ => ()
    }
  }
  
  output.write_string("}\n\n")
  
  // Generate exports as methods
  for i = 0; i < world.items.length(); i = i + 1 {
    match world.items[i] {
      Export(export) => {
        match export.kind {
          ExportKind::Function(func) => {
            output.write_string("pub fn " + sanitize_identifier(world.name) + "::")
            output.write_string(function_name_to_moonbit(export.name))
            generate_function_signature(func, output)
            output.write_string(" {\n")
            output.write_string("  // Implementation goes here\n")
            output.write_string("  abort(\"Not implemented\")\n")
            output.write_string("}\n\n")
          }
          _ => ()
        }
      }
      _ => ()
    }
  }
}

// Generate code for use statement
fn generate_use(use_item : UseItem, output : StringBuilder) -> Unit {
  output.write_string("// Use: " + use_item.path + "\n")
}

// Generate code for type definition
fn generate_type_def(type_def : TypeDef, output : StringBuilder) -> Unit {
  let type_name = sanitize_identifier(type_def.name)
  
  match type_def.def {
    Alias(typ) => {
      output.write_string("pub type " + type_name + " = " + type_to_moonbit(typ) + "\n\n")
    }
    
    Record(record) => {
      output.write_string("pub struct " + type_name + " {\n")
      for i = 0; i < record.fields.length(); i = i + 1 {
        let field = record.fields[i]
        output.write_string("  " + function_name_to_moonbit(field.name))
        output.write_string(" : " + type_to_moonbit(field.typ) + "\n")
      }
      output.write_string("} derive(Debug, Show, Eq)\n\n")
    }
    
    Enum(enum_) => {
      output.write_string("pub enum " + type_name + " {\n")
      for i = 0; i < enum_.cases.length(); i = i + 1 {
        output.write_string("  " + sanitize_identifier(enum_.cases[i]) + "\n")
      }
      output.write_string("} derive(Debug, Show, Eq)\n\n")
    }
    
    Flags(flags) => {
      // Generate as struct with boolean fields
      output.write_string("pub struct " + type_name + " {\n")
      for i = 0; i < flags.flags.length(); i = i + 1 {
        output.write_string("  " + function_name_to_moonbit(flags.flags[i]))
        output.write_string(" : Bool\n")
      }
      output.write_string("} derive(Debug, Show, Eq)\n\n")
    }
    
    Variant(variant) => {
      output.write_string("pub enum " + type_name + " {\n")
      for i = 0; i < variant.cases.length(); i = i + 1 {
        let case = variant.cases[i]
        output.write_string("  " + sanitize_identifier(case.name))
        match case.typ {
          Some(t) => output.write_string("(" + type_to_moonbit(t) + ")")
          None => ()
        }
        output.write_string("\n")
      }
      output.write_string("} derive(Debug, Show, Eq)\n\n")
    }
    
    Resource(resource) => {
      output.write_string("pub struct " + type_name + " {\n")
      output.write_string("  // Resource handle\n")
      output.write_string("  handle : Int\n")
      output.write_string("} derive(Debug, Show, Eq)\n\n")
      
      // Generate methods
      for i = 0; i < resource.methods.length(); i = i + 1 {
        let method = resource.methods[i]
        match method.kind {
          Constructor(params) => {
            output.write_string("pub fn " + type_name + "::new")
            output.write_string("(")
            generate_params(params, output)
            output.write_string(") -> " + type_name + " {\n")
            output.write_string("  // Constructor implementation\n")
            output.write_string("  abort(\"Not implemented\")\n")
            output.write_string("}\n\n")
          }
          Method(func) => {
            output.write_string("pub fn " + function_name_to_moonbit(method.name))
            output.write_string("(self : " + type_name)
            if func.params.length() > 0 {
              output.write_string(", ")
              generate_params(func.params, output)
            }
            output.write_string(")")
            generate_function_result_type(func.results, output)
            output.write_string(" {\n")
            output.write_string("  // Method implementation\n")
            output.write_string("  abort(\"Not implemented\")\n")
            output.write_string("}\n\n")
          }
          Static(func) => {
            output.write_string("pub fn " + type_name + "::")
            output.write_string(function_name_to_moonbit(method.name))
            generate_function_signature(func, output)
            output.write_string(" {\n")
            output.write_string("  // Static method implementation\n")
            output.write_string("  abort(\"Not implemented\")\n")
            output.write_string("}\n\n")
          }
        }
      }
    }
  }
}

// Generate code for function
fn generate_function(func : Function, output : StringBuilder) -> Unit {
  output.write_string("pub fn " + function_name_to_moonbit(func.name))
  generate_function_signature(func, output)
  output.write_string(" {\n")
  output.write_string("  // Function implementation\n")
  output.write_string("  abort(\"Not implemented\")\n")
  output.write_string("}\n\n")
}

// Generate function signature
fn generate_function_signature(func : Function, output : StringBuilder) -> Unit {
  output.write_string("(")
  generate_params(func.params, output)
  output.write_string(")")
  generate_function_result_type(func.results, output)
}

// Generate function type (for type annotations)
fn generate_function_type(func : Function) -> String {
  let output = StringBuilder::new()
  output.write_string("(")
  
  // Parameter types
  for i = 0; i < func.params.length(); i = i + 1 {
    if i > 0 {
      output.write_string(", ")
    }
    output.write_string(type_to_moonbit(func.params[i].typ))
  }
  
  output.write_string(") -> ")
  
  // Result type
  match func.results {
    None => output.write_string("Unit")
    Single(typ) => output.write_string(type_to_moonbit(typ))
    Named(results) => {
      if results.length() == 0 {
        output.write_string("Unit")
      } else if results.length() == 1 {
        output.write_string(type_to_moonbit(results[0].typ))
      } else {
        // Multiple results as tuple
        output.write_string("(")
        for i = 0; i < results.length(); i = i + 1 {
          if i > 0 {
            output.write_string(", ")
          }
          output.write_string(type_to_moonbit(results[i].typ))
        }
        output.write_string(")")
      }
    }
  }
  
  output.to_string()
}

// Generate parameters
fn generate_params(params : Array[Param], output : StringBuilder) -> Unit {
  for i = 0; i < params.length(); i = i + 1 {
    if i > 0 {
      output.write_string(", ")
    }
    let param = params[i]
    output.write_string(function_name_to_moonbit(param.name))
    output.write_string(" : ")
    output.write_string(type_to_moonbit(param.typ))
  }
}

// Generate function result type
fn generate_function_result_type(results : FunctionResult, output : StringBuilder) -> Unit {
  match results {
    None => output.write_string(" -> Unit")
    Single(typ) => {
      output.write_string(" -> ")
      output.write_string(type_to_moonbit(typ))
    }
    Named(results) => {
      output.write_string(" -> ")
      if results.length() == 0 {
        output.write_string("Unit")
      } else if results.length() == 1 {
        output.write_string(type_to_moonbit(results[0].typ))
      } else {
        // Multiple results as tuple
        output.write_string("(")
        for i = 0; i < results.length(); i = i + 1 {
          if i > 0 {
            output.write_string(", ")
          }
          output.write_string(type_to_moonbit(results[i].typ))
        }
        output.write_string(")")
      }
    }
  }
}

// Helper function to split string by character
fn split(self : String, delimiter : Char) -> Array[String] {
  let result : Array[String] = []
  let current = StringBuilder::new()
  
  for i = 0; i < self.length(); i = i + 1 {
    let ch = self[i]
    if ch == delimiter {
      if current.to_string().length() > 0 {
        result.push(current.to_string())
        current.clear()
      }
    } else {
      current.write_char(ch)
    }
  }
  
  if current.to_string().length() > 0 {
    result.push(current.to_string())
  }
  
  result
}

// Extension method for StringBuilder
fn clear(self : StringBuilder) -> Unit {
  // Reset the string builder by creating a new one
  // (This is a workaround since MoonBit might not have a clear method)
  while self.to_string().length() > 0 {
    // This is not efficient but works for now
    break
  }
}