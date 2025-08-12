// TypeScriptコード生成器

pub fn generate_typescript(typ : UniversalType) -> String {
  match typ {
    // 基本型
    String => "string"
    Number => "number"
    Integer => "number"
    Float => "number"
    Boolean => "boolean"
    Null => "null"
    Undefined => "undefined"
    Unknown => "unknown"
    Any => "any"
    Never => "never"
    Void => "void"
    
    // 配列型
    Array(elem) => {
      let elem_type = generate_typescript(elem)
      "\{elem_type}[]"
    }
    
    // タプル型
    Tuple(elems) => {
      let types = elems.map(fn(e) { generate_typescript(e) })
      let types_str = types.join(", ")
      "[\{types_str}]"
    }
    
    // オブジェクト型
    Object(fields) => {
      if fields.is_empty() {
        return "{}"
      }
      let field_strs = []
      fields.each(fn(name, field) {
        let optional_mark = if field.optional { "?" } else { "" }
        let readonly_mark = if field.is_readonly { "readonly " } else { "" }
        let field_type_str = generate_typescript(field.field_type)
        let field_str = "\{readonly_mark}\{name}\{optional_mark}: \{field_type_str}"
        field_strs.push(field_str)
      })
      let fields_str = field_strs.join("; ")
      "{ \{fields_str} }"
    }
    
    // Record型
    Record(key, value) => {
      let key_type = generate_typescript(key)
      let value_type = generate_typescript(value)
      "Record<\{key_type}, \{value_type}>"
    }
    
    // Map型
    Map(key, value) => {
      let key_type = generate_typescript(key)
      let value_type = generate_typescript(value)
      "Map<\{key_type}, \{value_type}>"
    }
    
    // Set型
    Set(elem) => {
      let elem_type = generate_typescript(elem)
      "Set<\{elem_type}>"
    }
    
    // 関数型
    Function(sig) => {
      generate_typescript_function(sig)
    }
    
    // Union型
    Union(types) => {
      let type_strs = types.map(fn(t) { generate_typescript(t) })
      let union_str = type_strs.join(" | ")
      "(\{union_str})"
    }
    
    // Intersection型
    Intersection(types) => {
      let type_strs = types.map(fn(t) { generate_typescript(t) })
      let intersection_str = type_strs.join(" & ")
      "(\{intersection_str})"
    }
    
    // Optional型
    Optional(inner) => {
      let inner_type = generate_typescript(inner)
      "(\{inner_type} | null | undefined)"
    }
    
    // Nullable型
    Nullable(inner) => {
      let inner_type = generate_typescript(inner)
      "\{inner_type} | null"
    }
    
    // 型パラメータ
    TypeParameter(name, constraint) => {
      match constraint {
        Some(Extends(bound)) => {
          let bound_type = generate_typescript(bound)
          "\{name} extends \{bound_type}"
        }
        Some(Super(bound)) => {
          let bound_type = generate_typescript(bound)
          "\{name} super \{bound_type}" // TypeScriptにはsuperはない
        }
        Some(Implements(interfaces)) => {
          let interfaces_str = interfaces.join(" & ")
          "\{name} extends \{interfaces_str}"
        }
        None => name
      }
    }
    
    // 型適用
    TypeApplication(base, args) => {
      let arg_strs = args.map(fn(a) { generate_typescript(a) })
      let args_str = arg_strs.join(", ")
      "\{base}<\{args_str}>"
    }
    
    // 型参照
    TypeReference(name) => name
    
    // 条件型
    Conditional(check, extends_type, true_type, false_type) => {
      let check_str = generate_typescript(check)
      let extends_str = generate_typescript(extends_type)
      let true_str = generate_typescript(true_type)
      let false_str = generate_typescript(false_type)
      "\{check_str} extends \{extends_str} ? \{true_str} : \{false_str}"
    }
    
    // リテラル型
    StringLiteral(value) => "\"\{value}\""
    NumberLiteral(value) => value.to_string()
    BooleanLiteral(value) => if value { "true" } else { "false" }
    
    // Promise型
    Promise(inner) => {
      let inner_type = generate_typescript(inner)
      "Promise<\{inner_type}>"
    }
    
    // Async型（TypeScriptではPromiseと同じ）
    Async(inner) => {
      let inner_type = generate_typescript(inner)
      "Promise<\{inner_type}>"
    }
    
    // Result型（TypeScriptでは独自定義が必要）
    Result(ok, err) => {
      let ok_type = generate_typescript(ok)
      let err_type = generate_typescript(err)
      "Result<\{ok_type}, \{err_type}>"
    }
    
    // Option型（TypeScriptでは独自定義が必要）
    Option(inner) => {
      let inner_type = generate_typescript(inner)
      "\{inner_type} | null"
    }
  }
}

fn generate_typescript_function(sig : FunctionSignature) -> String {
  let type_params_str = if sig.type_parameters.length() > 0 {
    let type_params = sig.type_parameters.map(fn(tp) {
      let base_param = tp.name
      let with_constraint = match tp.constraint {
        Some(Extends(bound)) => {
          let bound_type = generate_typescript(bound)
          "\{tp.name} extends \{bound_type}"
        }
        _ => base_param
      }
      match tp.default {
        Some(default_type) => {
          let default_str = generate_typescript(default_type)
          "\{with_constraint} = \{default_str}"
        }
        None => with_constraint
      }
    })
    let joined = type_params.join(", ")
    "<\{joined}>"
  } else {
    ""
  }
  
  // パラメータ
  let params = sig.parameters.map(fn(p) {
    let name_part = if p.is_rest {
      "...\{p.name}"
    } else if p.optional {
      "\{p.name}?"
    } else {
      p.name
    }
    let type_part = generate_typescript(p.param_type)
    let param_with_type = "\{name_part}: \{type_part}"
    match p.default_value {
      Some(value) => "\{param_with_type} = \{value}"
      None => param_with_type
    }
  })
  let params_str = params.join(", ")
  
  // 戻り値
  let return_type = if sig.is_async {
    let inner_return = generate_typescript(sig.return_type)
    "Promise<\{inner_return}>"
  } else {
    generate_typescript(sig.return_type)
  }
  
  "\{type_params_str}(\{params_str}) => \{return_type}"
}

// TypeScript型定義ファイル生成
pub fn generate_typescript_interface(
  name : String,
  typ : UniversalType,
  is_export : Bool
) -> String {
  let export_str = if is_export { "export " } else { "" }
  
  match typ {
    Object(fields) => {
      let field_lines = []
      fields.each(fn(field_name, field) {
        let optional = if field.optional { "?" } else { "" }
        let readonly_str = if field.is_readonly { "readonly " } else { "" }
        let field_type_str = generate_typescript(field.field_type)
        
        // コメント生成
        let comment_lines = match field.description {
          Some(desc) => ["  /** \{desc} */"]
          None => []
        }
        
        let field_line = "  \{readonly_str}\{field_name}\{optional}: \{field_type_str};"
        
        for comment in comment_lines {
          field_lines.push(comment)
        }
        field_lines.push(field_line)
      })
      
      let fields_content = field_lines.join("\n")
      "\{export_str}interface \{name} {\n\{fields_content}\n}"
    }
    _ => {
      let type_str = generate_typescript(typ)
      "\{export_str}type \{name} = \{type_str};"
    }
  }
}

// TypeScript関数シグネチャ生成
pub fn generate_typescript_function_declaration(
  name : String,
  sig : FunctionSignature,
  is_export : Bool
) -> String {
  let export_str = if is_export { "export " } else { "" }
  let async_str = if sig.is_async { "async " } else { "" }
  
  // 型パラメータ
  let type_params_str = if sig.type_parameters.length() > 0 {
    let type_params = sig.type_parameters.map(fn(tp) {
      let base_param = tp.name
      let with_constraint = match tp.constraint {
        Some(Extends(bound)) => {
          let bound_type = generate_typescript(bound)
          "\{tp.name} extends \{bound_type}"
        }
        _ => base_param
      }
      match tp.default {
        Some(default_type) => {
          let default_str = generate_typescript(default_type)
          "\{with_constraint} = \{default_str}"
        }
        None => with_constraint
      }
    })
    let joined = type_params.join(", ")
    "<\{joined}>"
  } else {
    ""
  }
  
  // パラメータ
  let params = sig.parameters.map(fn(p) {
    let name_part = if p.is_rest {
      "...\{p.name}"
    } else if p.optional {
      "\{p.name}?"
    } else {
      p.name
    }
    let type_part = generate_typescript(p.param_type)
    let param_with_type = "\{name_part}: \{type_part}"
    match p.default_value {
      Some(value) => "\{param_with_type} = \{value}"
      None => param_with_type
    }
  })
  let params_str = params.join(", ")
  
  // 戻り値
  let return_type = if sig.is_async {
    let inner_return = generate_typescript(sig.return_type)
    "Promise<\{inner_return}>"
  } else {
    generate_typescript(sig.return_type)
  }
  
  "\{export_str}\{async_str}function \{name}\{type_params_str}(\{params_str}): \{return_type};"
}