// Python+Pyrightコード生成器

pub fn generate_python(typ : UniversalType) -> String {
  match typ {
    // 基本型
    String => "str"
    Number => "float"
    Integer => "int"
    Float => "float"
    Boolean => "bool"
    Null => "None"
    Undefined => "None"
    Unknown => "Any"
    Any => "Any"
    Never => "NoReturn"
    Void => "None"
    
    // 配列型
    Array(elem) => {
      let elem_type = generate_python(elem)
      "List[\{elem_type}]"
    }
    
    // タプル型
    Tuple(elems) => {
      if elems.is_empty() {
        "Tuple[()]"
      } else {
        let types = elems.map(fn(e) { generate_python(e) })
        let types_str = types.join(", ")
        "Tuple[\{types_str}]"
      }
    }
    
    // オブジェクト型（TypedDictで表現）
    Object(_fields) => {
      // Pythonでは匿名TypedDictは作れないので、型名が必要
      "Dict[str, Any]"
    }
    
    // Record型（Dictで表現）
    Record(key, value) => {
      let key_type = generate_python(key)
      let value_type = generate_python(value)
      "Dict[\{key_type}, \{value_type}]"
    }
    
    // Map型（Dictで表現）
    Map(key, value) => {
      let key_type = generate_python(key)
      let value_type = generate_python(value)
      "Dict[\{key_type}, \{value_type}]"
    }
    
    // Set型
    Set(elem) => {
      let elem_type = generate_python(elem)
      "Set[\{elem_type}]"
    }
    
    // 関数型
    Function(sig) => {
      generate_python_callable(sig)
    }
    
    // Union型
    Union(types) => {
      let type_strs = types.map(fn(t) { generate_python(t) })
      let union_str = type_strs.join(" | ")
      union_str
    }
    
    // Intersection型（Pythonではサポートされない、Protocolで部分的に代替）
    Intersection(_types) => {
      "Any  # Intersection not directly supported"
    }
    
    // Optional型
    Optional(inner) => {
      let inner_type = generate_python(inner)
      "Optional[\{inner_type}]"
    }
    
    // Nullable型
    Nullable(inner) => {
      let inner_type = generate_python(inner)
      "\{inner_type} | None"
    }
    
    // 型パラメータ
    TypeParameter(name, _constraint) => name
    
    // 型適用
    TypeApplication(base, args) => {
      let arg_strs = args.map(fn(a) { generate_python(a) })
      let args_str = arg_strs.join(", ")
      "\{base}[\{args_str}]"
    }
    
    // 型参照
    TypeReference(name) => name
    
    // 条件型（Pythonではサポートされない）
    Conditional(_check, _extends_type, _true_type, _false_type) => {
      "Any  # Conditional type not supported"
    }
    
    // リテラル型
    StringLiteral(value) => "Literal[\"\{value}\"]"
    NumberLiteral(value) => {
      // 整数の場合は小数点を除去
      let int_value = value.to_int()
      let double_value : Double = int_value.to_double()
      if double_value == value.to_double() {
        "Literal[\{int_value}]"
      } else {
        "Literal[\{value}]"
      }
    }
    BooleanLiteral(value) => if value { "Literal[True]" } else { "Literal[False]" }
    
    // Promise型（Pythonではawaitableで代替）
    Promise(inner) => {
      let inner_type = generate_python(inner)
      "Awaitable[\{inner_type}]"
    }
    
    // Async型
    Async(inner) => {
      let inner_type = generate_python(inner)
      "Awaitable[\{inner_type}]"
    }
    
    // Result型（Pythonでは独自定義が必要）
    Result(ok, err) => {
      let ok_type = generate_python(ok)
      let err_type = generate_python(err)
      "\{ok_type} | \{err_type}"
    }
    
    // Option型
    Option(inner) => {
      let inner_type = generate_python(inner)
      "Optional[\{inner_type}]"
    }
  }
}

fn generate_python_callable(sig : FunctionSignature) -> String {
  // パラメータ型
  let param_types = sig.parameters.map(fn(p) {
    generate_python(p.param_type)
  })
  
  // 戻り値型
  let return_type = if sig.is_async {
    let inner_type = generate_python(sig.return_type)
    "Awaitable[\{inner_type}]"
  } else {
    generate_python(sig.return_type)
  }
  
  // Callable[[param1, param2, ...], return_type]
  if param_types.is_empty() {
    "Callable[[], \{return_type}]"
  } else {
    let params_str = param_types.join(", ")
    "Callable[[\{params_str}], \{return_type}]"
  }
}

// Python TypedDict生成
pub fn generate_python_typed_dict(
  name : String,
  fields : Map[String, ObjectField],
  _total : Bool
) -> String {
  let field_lines = []
  let required_fields = []
  let optional_fields = []
  
  fields.each(fn(field_name, field) {
    let field_type = generate_python(field.field_type)
    let field_line = "    \{field_name}: \{field_type}"
    
    if field.optional {
      optional_fields.push(field_line)
    } else {
      required_fields.push(field_line)
    }
  })
  
  // TypedDictの生成
  if optional_fields.is_empty() {
    // すべて必須フィールド
    let all_fields = required_fields
    let fields_str = all_fields.join("\n")
    "class \{name}(TypedDict):\n\{fields_str}"
  } else if required_fields.is_empty() {
    // すべてオプショナルフィールド
    let all_fields = optional_fields
    let fields_str = all_fields.join("\n")
    "class \{name}(TypedDict, total=False):\n\{fields_str}"
  } else {
    // 混在している場合は、継承を使用
    let required_str = required_fields.join("\n")
    let optional_str = optional_fields.join("\n")
    
    "class \{name}Required(TypedDict):\n\{required_str}\n\nclass \{name}(\{name}Required, total=False):\n\{optional_str}"
  }
}

// Python関数定義生成
pub fn generate_python_function(
  name : String,
  sig : FunctionSignature,
  include_body : Bool
) -> String {
  let async_prefix = if sig.is_async { "async " } else { "" }
  
  // 型パラメータ（TypeVarとして定義）
  let type_var_defs = []
  for type_param in sig.type_parameters {
    let type_var = generate_python_type_var(type_param)
    type_var_defs.push(type_var)
  }
  
  // パラメータ
  let params = sig.parameters.map(fn(p) {
    let param_name = if p.is_rest {
      "*\{p.name}"
    } else {
      p.name
    }
    
    let param_type = generate_python(p.param_type)
    
    let param_with_type = "\{param_name}: \{param_type}"
    
    // デフォルト値
    match p.default_value {
      Some(value) => "\{param_with_type} = \{value}"
      None => {
        if p.optional {
          "\{param_with_type} = None"
        } else {
          param_with_type
        }
      }
    }
  })
  
  let params_str = if params.is_empty() {
    ""
  } else {
    params.join(", ")
  }
  
  // 戻り値
  let return_type = if sig.is_async {
    let inner_type = generate_python(sig.return_type)
    "Awaitable[\{inner_type}]"
  } else {
    generate_python(sig.return_type)
  }
  
  // TypeVar定義を先に出力
  let type_var_section = if type_var_defs.is_empty() {
    ""
  } else {
    let joined = type_var_defs.join("\n")
    "\{joined}\n\n"
  }
  
  // 関数定義
  let func_def = "\{async_prefix}def \{name}(\{params_str}) -> \{return_type}:"
  
  if include_body {
    "\{type_var_section}\{func_def}\n    pass"
  } else {
    "\{type_var_section}\{func_def}\n    ..."
  }
}

fn generate_python_type_var(type_param : TypeParameter) -> String {
  let type_var_name = type_param.name
  
  let constraint_part = match type_param.constraint {
    Some(Extends(bound)) => {
      let bound_type = generate_python(bound)
      ", bound=\{bound_type}"
    }
    Some(Super(_bound)) => {
      // Pythonには下限境界がない
      ""
    }
    Some(Implements(_interfaces)) => {
      // Pythonでは直接的なimplementsはない
      ""
    }
    None => ""
  }
  
  let variance_part = match type_param.variance {
    Some(Covariant) => ", covariant=True"
    Some(Contravariant) => ", contravariant=True"
    Some(Invariant) => ""
    None => ""
  }
  
  "\{type_var_name} = TypeVar('\{type_var_name}'\{constraint_part}\{variance_part})"
}

// Python型エイリアス生成
pub fn generate_python_type_alias(
  name : String,
  typ : UniversalType
) -> String {
  let type_str = generate_python(typ)
  "\{name} = \{type_str}"
}

// Pythonクラス定義生成（Union型の代替）
pub fn generate_python_union_class(
  name : String,
  variants : Array[UniversalType]
) -> String {
  let variant_types = variants.map(fn(v) { generate_python(v) })
  let union_str = variant_types.join(" | ")
  "\{name} = \{union_str}"
}

// Python Protocol生成（Intersection型の部分的な代替）
pub fn generate_python_protocol(
  name : String,
  methods : Map[String, FunctionSignature]
) -> String {
  let method_lines = []
  
  methods.each(fn(method_name, sig) {
    let method_def = generate_python_method_signature(method_name, sig)
    method_lines.push("    \{method_def}")
  })
  
  let methods_str = method_lines.join("\n")
  "class \{name}(Protocol):\n\{methods_str}"
}

fn generate_python_method_signature(
  name : String,
  sig : FunctionSignature
) -> String {
  let async_prefix = if sig.is_async { "async " } else { "" }
  
  // selfパラメータを追加
  let params = ["self"]
  
  // 通常のパラメータ
  for param in sig.parameters {
    let param_name = if param.is_rest {
      "*\{param.name}"
    } else {
      param.name
    }
    
    let param_type = generate_python(param.param_type)
    let param_with_type = "\{param_name}: \{param_type}"
    
    match param.default_value {
      Some(value) => params.push("\{param_with_type} = \{value}")
      None => {
        if param.optional {
          params.push("\{param_with_type} = None")
        } else {
          params.push(param_with_type)
        }
      }
    }
  }
  
  let params_str = params.join(", ")
  
  // 戻り値
  let return_type = if sig.is_async {
    let inner_type = generate_python(sig.return_type)
    "Awaitable[\{inner_type}]"
  } else {
    generate_python(sig.return_type)
  }
  
  "\{async_prefix}def \{name}(\{params_str}) -> \{return_type}: ..."
}

// Pythonインポート文生成
pub fn generate_python_imports(types : Array[UniversalType]) -> String {
  let imports = Map::new()
  
  // 使用されている型に応じて必要なインポートを収集
  for typ in types {
    collect_python_imports(typ, imports)
  }
  
  // インポート文を生成
  let typing_imports = []
  let collections_imports = []
  let other_imports = []
  
  imports.each(fn(mod, items) {
    if mod == "typing" {
      for item in items {
        typing_imports.push(item)
      }
    } else if mod == "collections.abc" {
      for item in items {
        collections_imports.push(item)
      }
    } else {
      for item in items {
        other_imports.push("from \{mod} import \{item}")
      }
    }
  })
  
  let import_lines = []
  
  if not(typing_imports.is_empty()) {
    let sorted_typing = typing_imports
    let typing_str = sorted_typing.join(", ")
    import_lines.push("from typing import \{typing_str}")
  }
  
  if not(collections_imports.is_empty()) {
    let sorted_collections = collections_imports
    let collections_str = sorted_collections.join(", ")
    import_lines.push("from collections.abc import \{collections_str}")
  }
  
  for other_import in other_imports {
    import_lines.push(other_import)
  }
  
  import_lines.join("\n")
}

fn collect_python_imports(typ : UniversalType, imports : Map[String, Array[String]]) -> Unit {
  match typ {
    Array(elem) => {
      add_import(imports, "typing", "List")
      collect_python_imports(elem, imports)
    }
    Tuple(elems) => {
      add_import(imports, "typing", "Tuple")
      for elem in elems {
        collect_python_imports(elem, imports)
      }
    }
    Record(key, value) | Map(key, value) => {
      add_import(imports, "typing", "Dict")
      collect_python_imports(key, imports)
      collect_python_imports(value, imports)
    }
    Set(elem) => {
      add_import(imports, "typing", "Set")
      collect_python_imports(elem, imports)
    }
    Function(sig) => {
      add_import(imports, "typing", "Callable")
      if sig.is_async {
        add_import(imports, "collections.abc", "Awaitable")
      }
      for param in sig.parameters {
        collect_python_imports(param.param_type, imports)
      }
      collect_python_imports(sig.return_type, imports)
    }
    Union(types) => {
      for t in types {
        collect_python_imports(t, imports)
      }
    }
    Optional(inner) => {
      add_import(imports, "typing", "Optional")
      collect_python_imports(inner, imports)
    }
    Promise(inner) | Async(inner) => {
      add_import(imports, "collections.abc", "Awaitable")
      collect_python_imports(inner, imports)
    }
    StringLiteral(_) | NumberLiteral(_) | BooleanLiteral(_) => {
      add_import(imports, "typing", "Literal")
    }
    Unknown | Any => {
      add_import(imports, "typing", "Any")
    }
    Never => {
      add_import(imports, "typing", "NoReturn")
    }
    _ => ()
  }
}

fn add_import(imports : Map[String, Array[String]], mod : String, item : String) -> Unit {
  match imports.get(mod) {
    Some(items) => {
      // 重複を避ける
      let mut found = false
      for existing in items {
        if existing == item {
          found = true
          break
        }
      }
      if not(found) {
        items.push(item)
      }
    }
    None => {
      let items = [item]
      imports.set(mod, items)
    }
  }
}