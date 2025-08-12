// MoonBitコード生成器

pub fn generate_moonbit(typ : UniversalType) -> String {
  match typ {
    // 基本型
    String => "String"
    Number => "Double"
    Integer => "Int"
    Float => "Double"
    Boolean => "Bool"
    Null => "Unit" // MoonBitにはnullがないのでUnitで代替
    Undefined => "Unit" // MoonBitにはundefinedがないのでUnitで代替
    Unknown => "Any" // MoonBitにはAny型がない場合は独自定義が必要
    Any => "Any" // MoonBitにはAny型がない場合は独自定義が必要
    Never => "Nothing" // MoonBitにはNever型がない場合は独自定義が必要
    Void => "Unit"
    
    // 配列型
    Array(elem) => {
      let elem_type = generate_moonbit(elem)
      "Array[\{elem_type}]"
    }
    
    // タプル型
    Tuple(elems) => {
      let types = elems.map(fn(e) { generate_moonbit(e) })
      let types_str = types.join(", ")
      "(\{types_str})"
    }
    
    // オブジェクト型（構造体として表現）
    Object(_fields) => {
      // MoonBitでは匿名構造体は作れないので、型名が必要
      "{ /* struct fields */ }"
    }
    
    // Record型（Mapとして表現）
    Record(key, value) => {
      let key_type = generate_moonbit(key)
      let value_type = generate_moonbit(value)
      "Map[\{key_type}, \{value_type}]"
    }
    
    // Map型
    Map(key, value) => {
      let key_type = generate_moonbit(key)
      let value_type = generate_moonbit(value)
      "Map[\{key_type}, \{value_type}]"
    }
    
    // Set型
    Set(elem) => {
      let elem_type = generate_moonbit(elem)
      "Set[\{elem_type}]"
    }
    
    // 関数型
    Function(sig) => {
      generate_moonbit_function_type(sig)
    }
    
    // Union型（MoonBitではenumで表現）
    Union(_types) => {
      // MoonBitではUnion型は直接サポートされないため、enumで代替
      "/* Union type - use enum */\n"
    }
    
    // Intersection型（MoonBitではサポートされない）
    Intersection(_types) => {
      "/* Intersection type - not supported */"
    }
    
    // Optional型（Option型で表現）
    Optional(inner) => {
      let inner_type = generate_moonbit(inner)
      "\{inner_type}?"
    }
    
    // Nullable型（Option型で表現）
    Nullable(inner) => {
      let inner_type = generate_moonbit(inner)
      "\{inner_type}?"
    }
    
    // 型パラメータ
    TypeParameter(name, _constraint) => name
    
    // 型適用
    TypeApplication(base, args) => {
      let arg_strs = args.map(fn(a) { generate_moonbit(a) })
      let args_str = arg_strs.join(", ")
      "\{base}[\{args_str}]"
    }
    
    // 型参照
    TypeReference(name) => name
    
    // 条件型（MoonBitではサポートされない）
    Conditional(_check, _extends_type, _true_type, _false_type) => {
      "/* Conditional type - not supported */"
    }
    
    // リテラル型（MoonBitではサポートされない）
    StringLiteral(value) => "String /* literal: \"\{value}\" */"
    NumberLiteral(value) => "Double /* literal: \{value} */"
    BooleanLiteral(value) => "Bool /* literal: \{value} */"
    
    // Promise型（MoonBitではResultで代替）
    Promise(inner) => {
      let inner_type = generate_moonbit(inner)
      "Result[\{inner_type}, Error]"
    }
    
    // Async型（MoonBitではResultで代替）
    Async(inner) => {
      let inner_type = generate_moonbit(inner)
      "Result[\{inner_type}, Error]"
    }
    
    // Result型
    Result(ok, err) => {
      let ok_type = generate_moonbit(ok)
      let err_type = generate_moonbit(err)
      "Result[\{ok_type}, \{err_type}]"
    }
    
    // Option型
    Option(inner) => {
      let inner_type = generate_moonbit(inner)
      "\{inner_type}?"
    }
  }
}

fn generate_moonbit_function_type(sig : FunctionSignature) -> String {
  // 型パラメータ
  let type_params_str = if sig.type_parameters.length() > 0 {
    let type_param_names = sig.type_parameters.map(fn(tp) { tp.name })
    let joined = type_param_names.join(", ")
    "[\{joined}]"
  } else {
    ""
  }
  
  // パラメータ型
  let param_types = sig.parameters.map(fn(p) {
    if p.optional {
      let inner_type = generate_moonbit(p.param_type)
      "\{inner_type}?"
    } else {
      generate_moonbit(p.param_type)
    }
  })
  
  // 戻り値型
  let return_type = if sig.is_async {
    let inner_type = generate_moonbit(sig.return_type)
    "Result[\{inner_type}, Error]"
  } else {
    generate_moonbit(sig.return_type)
  }
  
  // 関数型の組み立て
  if param_types.is_empty() {
    "\{type_params_str}() -> \{return_type}"
  } else {
    let params_str = param_types.join(", ")
    "\{type_params_str}(\{params_str}) -> \{return_type}"
  }
}

// MoonBit構造体定義生成
pub fn generate_moonbit_struct(
  name : String,
  fields : Map[String, ObjectField],
  is_public : Bool
) -> String {
  let visibility = if is_public { "pub " } else { "" }
  let field_lines = []
  
  fields.each(fn(field_name, field) {
    let field_type = if field.optional {
      let inner = generate_moonbit(field.field_type)
      "\{inner}?"
    } else {
      generate_moonbit(field.field_type)
    }
    
    // MoonBitではreadonlyはデフォルト、mutが必要な場合のみ指定
    let mutability = if field.is_readonly { "" } else { "mut " }
    
    let field_line = "  \{mutability}\{field_name} : \{field_type}"
    field_lines.push(field_line)
  })
  
  let fields_str = field_lines.join("\n")
  "\{visibility}struct \{name} {\n\{fields_str}\n}"
}

// MoonBit enum定義生成（Union型の代替）
pub fn generate_moonbit_enum(
  name : String,
  variants : Array[UniversalType],
  is_public : Bool
) -> String {
  let visibility = if is_public { "pub " } else { "" }
  let variant_lines = []
  
  for i = 0; i < variants.length(); i = i + 1 {
    let variant = variants[i]
    let variant_name = "Variant\{i + 1}"
    let variant_type = generate_moonbit(variant)
    let variant_line = "  \{variant_name}(\{variant_type})"
    variant_lines.push(variant_line)
  }
  
  let variants_str = variant_lines.join("\n")
  "\{visibility}enum \{name} {\n\{variants_str}\n}"
}

// MoonBit関数定義生成
pub fn generate_moonbit_function(
  name : String,
  sig : FunctionSignature,
  is_public : Bool
) -> String {
  let visibility = if is_public { "pub " } else { "" }
  
  // 型パラメータ
  let type_params_str = if sig.type_parameters.length() > 0 {
    let type_param_names = sig.type_parameters.map(fn(tp) { tp.name })
    let joined = type_param_names.join(", ")
    "[\{joined}]"
  } else {
    ""
  }
  
  // パラメータ
  let params = sig.parameters.map(fn(p) {
    let param_type = if p.optional {
      let inner_type = generate_moonbit(p.param_type)
      "\{inner_type}?"
    } else {
      generate_moonbit(p.param_type)
    }
    
    let param_str = "\{p.name} : \{param_type}"
    
    // デフォルト値はMoonBitでは関数シグネチャには含まれない
    // （呼び出し側で処理）
    param_str
  })
  let params_str = if params.is_empty() {
    ""
  } else {
    let joined = params.join(", ")
    joined
  }
  
  // 戻り値
  let return_type = if sig.is_async {
    let inner_type = generate_moonbit(sig.return_type)
    "Result[\{inner_type}, Error]"
  } else {
    generate_moonbit(sig.return_type)
  }
  
  // エラーハンドリング
  let error_suffix = match sig.throws {
    Some(_error_type) => {
      "!"
    }
    None => ""
  }
  
  "\{visibility}fn \{name}\{type_params_str}(\{params_str}) -> \{return_type}\{error_suffix}"
}

// MoonBit型エイリアス生成
pub fn generate_moonbit_type_alias(
  name : String,
  typ : UniversalType,
  is_public : Bool
) -> String {
  let visibility = if is_public { "pub " } else { "" }
  let type_str = generate_moonbit(typ)
  "\{visibility}typealias \{type_str} as \{name}"
}