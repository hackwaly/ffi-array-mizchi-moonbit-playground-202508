// 関数型のバリデーション機能

pub struct ValidationContext {
  mut errors : Array[ValidationError]
  mut type_registry : TypeRegistry
  mut current_path : Array[String]
}

pub struct ValidationError {
  path : String
  expected : LambdaType
  actual : String
  message : String
}

pub fn ValidationContext::new(registry : TypeRegistry) -> ValidationContext {
  {
    errors: Array::new(),
    type_registry: registry,
    current_path: Array::new()
  }
}

pub fn push_path(self : ValidationContext, segment : String) -> Unit {
  self.current_path.push(segment)
}

pub fn pop_path(self : ValidationContext) -> Unit {
  ignore(self.current_path.pop())
}

pub fn get_path(self : ValidationContext) -> String {
  self.current_path.join(".")
}

pub fn add_error(
  self : ValidationContext,
  expected : LambdaType,
  actual : String,
  message : String
) -> Unit {
  self.errors.push({
    path: self.get_path(),
    expected: expected,
    actual: actual,
    message: message
  })
}

// 値の型チェック
pub fn validate_value(
  value : @json.JsonValue,
  expected_type : LambdaType,
  context : ValidationContext
) -> Bool {
  match (value, expected_type) {
    // 基本型
    (@json.JsonValue::Null, Null) => true
    (@json.JsonValue::True | @json.JsonValue::False, Schema("boolean")) => true
    (@json.JsonValue::Number(_), Schema("number")) => true
    (@json.JsonValue::Number(n), Schema("integer")) => {
      // 整数チェック
      let int_value = n.to_int()
      if int_value.to_double() == n {
        true
      } else {
        context.add_error(expected_type, "number", "Expected integer but got decimal")
        false
      }
    }
    (@json.JsonValue::String(_), Schema("string")) => true
    
    // Any型は全てを受け入れる
    (_, Any) => true
    
    // Never型は何も受け入れない
    (_, Never) => {
      context.add_error(expected_type, "any", "Never type cannot accept any value")
      false
    }
    
    // 配列型
    (@json.JsonValue::Array(items), Array(elem_type)) => {
      let mut all_valid = true
      for i, item in items {
        context.push_path("[" + i.to_string() + "]")
        if not(validate_value(item, elem_type, context)) {
          all_valid = false
        }
        context.pop_path()
      }
      all_valid
    }
    
    // タプル型
    (@json.JsonValue::Array(items), Tuple(elem_types)) => {
      if items.length() != elem_types.length() {
        context.add_error(
          expected_type,
          "array[" + items.length().to_string() + "]",
          "Tuple length mismatch"
        )
        return false
      }
      let mut all_valid = true
      for i in 0..<items.length() {
        context.push_path("[" + i.to_string() + "]")
        if not(validate_value(items[i], elem_types[i], context)) {
          all_valid = false
        }
        context.pop_path()
      }
      all_valid
    }
    
    // Union型
    (v, Union(types)) => {
      // いずれかの型にマッチすればOK
      for t in types {
        let temp_context = ValidationContext::new(context.type_registry)
        if validate_value(v, t, temp_context) {
          return true
        }
      }
      context.add_error(expected_type, value_type_name(v), "No matching union type")
      false
    }
    
    // Intersection型
    (v, Intersection(types)) => {
      // 全ての型にマッチする必要がある
      let mut all_valid = true
      for t in types {
        if not(validate_value(v, t, context)) {
          all_valid = false
        }
      }
      all_valid
    }
    
    // 参照型の解決
    (v, Ref(ref_name)) => {
      match context.type_registry.resolve(ref_name) {
        Some(resolved_type) => validate_value(v, resolved_type, context)
        None => {
          context.add_error(expected_type, value_type_name(v), "Unresolved type reference: " + ref_name)
          false
        }
      }
    }
    
    // オブジェクト（関数型のチェック）
    (@json.JsonValue::Object(obj), Function(func_type)) => {
      // 関数のメタデータをチェック
      match obj.get("$function") {
        Some(@json.JsonValue::True) => true
        _ => {
          context.add_error(expected_type, "object", "Expected function metadata")
          false
        }
      }
    }
    
    _ => {
      context.add_error(
        expected_type,
        value_type_name(value),
        "Type mismatch"
      )
      false
    }
  }
}

// 関数呼び出しの引数チェック
pub fn validate_function_call(
  func : FunctionType,
  args : Array[@json.JsonValue],
  context : ValidationContext
) -> Bool {
  // 必須引数の数をチェック
  let required_count = func.parameters.filter(fn(p) { not(p.optional) }).length()
  if args.length() < required_count {
    context.add_error(
      Function(func),
      "arguments[" + args.length().to_string() + "]",
      "Too few arguments"
    )
    return false
  }
  
  if args.length() > func.parameters.length() {
    context.add_error(
      Function(func),
      "arguments[" + args.length().to_string() + "]",
      "Too many arguments"
    )
    return false
  }
  
  // 各引数の型チェック
  let mut all_valid = true
  for i in 0..<args.length() {
    let param = func.parameters[i]
    context.push_path("arg[" + i.to_string() + "]")
    if not(validate_value(args[i], param.param_type, context)) {
      all_valid = false
    }
    context.pop_path()
  }
  
  // オプショナル引数のデフォルト値チェック
  for i in args.length()..<func.parameters.length() {
    let param = func.parameters[i]
    if not(param.optional) && param.default_value.is_none() {
      context.add_error(
        Function(func),
        "missing",
        "Required parameter missing: " + param.name
      )
      all_valid = false
    }
  }
  
  all_valid
}

// 型パラメータの制約チェック
pub fn validate_type_constraints(
  type_args : Map[TypeName, LambdaType],
  type_params : Array[TypeParameter],
  context : ValidationContext
) -> Bool {
  let mut all_valid = true
  
  for param in type_params {
    match type_args.get(param.name) {
      Some(arg_type) => {
        match param.constraint {
          Some(constraint) => {
            if not(check_type_constraint(arg_type, constraint)) {
              context.add_error(
                TypeParameter(param.name),
                type_to_string(arg_type),
                "Type constraint not satisfied"
              )
              all_valid = false
            }
          }
          None => ()
        }
      }
      None => {
        context.add_error(
          TypeParameter(param.name),
          "missing",
          "Type parameter not provided"
        )
        all_valid = false
      }
    }
  }
  
  all_valid
}

// ヘルパー関数
fn value_type_name(value : @json.JsonValue) -> String {
  match value {
    @json.JsonValue::Null => "null"
    @json.JsonValue::True | @json.JsonValue::False => "boolean"
    @json.JsonValue::Number(_) => "number"
    @json.JsonValue::String(_) => "string"
    @json.JsonValue::Array(_) => "array"
    @json.JsonValue::Object(_) => "object"
  }
}

fn type_to_string(t : LambdaType) -> String {
  match t {
    Null => "null"
    Undefined => "undefined"
    Void => "void"
    Any => "any"
    Never => "never"
    Schema(s) => s
    Array(elem) => type_to_string(elem) + "[]"
    Tuple(elems) => "[" + elems.map(type_to_string).join(", ") + "]"
    Union(types) => types.map(type_to_string).join(" | ")
    Intersection(types) => types.map(type_to_string).join(" & ")
    TypeParameter(name) => "<" + name + ">"
    Ref(name) => name
    Function(f) => {
      let params = f.parameters.map(fn(p) {
        p.name + ": " + type_to_string(p.param_type)
      }).join(", ")
      "(" + params + ") => " + type_to_string(f.return_type)
    }
    _ => "unknown"
  }
}