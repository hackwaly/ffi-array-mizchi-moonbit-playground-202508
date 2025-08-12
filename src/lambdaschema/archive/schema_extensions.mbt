// JSON Schema拡張仕様の定義
// lambdaschemaはJSON Schemaの拡張として関数型を表現する

// JSON Schema拡張キーワード
pub enum ExtensionKeyword {
  Function       // "$function": true
  Parameters     // "$parameters": [...]
  Returns        // "$returns": {...}
  Throws         // "$throws": {...}
  TypeParam      // "$typeParam": "T"
  TypeArgs       // "$typeArgs": ["String", "Number"]
  Async          // "$async": "Promise"
  Effect         // "$effect": {...}
  Generic        // "$generic": ["T", "U"]
  Constraint     // "$constraint": {"T": {"extends": "..."}}
}

// JSON表現として出力される拡張スキーマ
pub struct ExtendedSchema {
  base : @json.JsonValue                    // 基本のJSON Schema
  extensions : Map[String, @json.JsonValue] // 拡張プロパティ
}

// 関数型のJSON Schema表現
// {
//   "$function": true,
//   "$parameters": [
//     {"name": "x", "type": {...}, "optional": false},
//     {"name": "y", "type": {...}, "optional": true}
//   ],
//   "$returns": {...},
//   "$throws": {...},
//   "$generic": ["T", "U"],
//   "$constraint": {"T": {"extends": {...}}}
// }
pub fn function_schema_json(
  parameters : Array[@json.JsonValue],
  returns : @json.JsonValue,
  throws : @json.JsonValue?,
  generics : Array[String]?,
  constraints : Map[String, @json.JsonValue]?
) -> @json.JsonValue {
  let obj = Map::new()
  
  // 関数マーカー
  obj["$function"] = @json.JsonValue::True
  
  // パラメータ
  obj["$parameters"] = @json.JsonValue::Array(parameters)
  
  // 戻り値
  obj["$returns"] = returns
  
  // 例外
  match throws {
    Some(t) => obj["$throws"] = t
    None => ()
  }
  
  // ジェネリクス
  match generics {
    Some(g) => {
      let generic_values = g.map(fn(name) { @json.JsonValue::String(name) })
      obj["$generic"] = @json.JsonValue::Array(generic_values)
    }
    None => ()
  }
  
  // 制約
  match constraints {
    Some(c) => {
      let constraint_obj = Map::new()
      for name, constraint in c {
        constraint_obj[name] = constraint
      }
      obj["$constraint"] = @json.JsonValue::Object(constraint_obj)
    }
    None => ()
  }
  
  @json.JsonValue::Object(obj)
}

// 非同期型のJSON Schema表現
// {
//   "$async": "Promise",
//   "$resolves": {...}
// }
pub fn async_schema_json(
  async_type : String,
  resolves : @json.JsonValue
) -> @json.JsonValue {
  let obj = Map::new()
  obj["$async"] = @json.JsonValue::String(async_type)
  obj["$resolves"] = resolves
  @json.JsonValue::Object(obj)
}

// Result型のJSON Schema表現
// {
//   "$result": true,
//   "$ok": {...},
//   "$error": {...}
// }
pub fn result_schema_json(
  ok_type : @json.JsonValue,
  error_type : @json.JsonValue
) -> @json.JsonValue {
  let obj = Map::new()
  obj["$result"] = @json.JsonValue::True
  obj["$ok"] = ok_type
  obj["$error"] = error_type
  @json.JsonValue::Object(obj)
}

// Effect型のJSON Schema表現
// {
//   "$effect": "IO",
//   "$value": {...},
//   "$effects": ["read", "write"]
// }
pub fn effect_schema_json(
  effect_name : String,
  value_type : @json.JsonValue,
  effects : Array[String]
) -> @json.JsonValue {
  let obj = Map::new()
  obj["$effect"] = @json.JsonValue::String(effect_name)
  obj["$value"] = value_type
  let effect_values = effects.map(fn(e) { @json.JsonValue::String(e) })
  obj["$effects"] = @json.JsonValue::Array(effect_values)
  @json.JsonValue::Object(obj)
}

// 高階型のJSON Schema表現
// {
//   "$higherKinded": "F",
//   "$kind": "* -> *",
//   "$applied": [{...}]
// }
pub fn higher_kinded_json(
  name : String,
  kind : String,
  applied : Array[@json.JsonValue]?
) -> @json.JsonValue {
  let obj = Map::new()
  obj["$higherKinded"] = @json.JsonValue::String(name)
  obj["$kind"] = @json.JsonValue::String(kind)
  
  match applied {
    Some(args) => obj["$applied"] = @json.JsonValue::Array(args)
    None => ()
  }
  
  @json.JsonValue::Object(obj)
}

// 型パラメータのJSON表現
// {
//   "$typeParam": "T",
//   "$constraint": {"extends": {...}}
// }
pub fn type_param_json(
  name : String,
  constraint : @json.JsonValue?
) -> @json.JsonValue {
  let obj = Map::new()
  obj["$typeParam"] = @json.JsonValue::String(name)
  
  match constraint {
    Some(c) => obj["$constraint"] = c
    None => ()
  }
  
  @json.JsonValue::Object(obj)
}

// 型参照のJSON表現
// {
//   "$ref": "#/definitions/User",
//   "$typeArgs": ["String", "Number"]
// }
pub fn ref_with_args_json(
  ref_path : String,
  type_args : Array[@json.JsonValue]?
) -> @json.JsonValue {
  let obj = Map::new()
  obj["$ref"] = @json.JsonValue::String(ref_path)
  
  match type_args {
    Some(args) => obj["$typeArgs"] = @json.JsonValue::Array(args)
    None => ()
  }
  
  @json.JsonValue::Object(obj)
}

// 通常のJSON Schemaと拡張を統合
pub fn merge_with_schema(
  base_schema : @json.JsonValue,
  extensions : Map[String, @json.JsonValue]
) -> @json.JsonValue {
  match base_schema {
    @json.JsonValue::Object(obj) => {
      let merged = Map::new()
      
      // 既存のプロパティをコピー
      for key, value in obj {
        merged[key] = value
      }
      
      // 拡張プロパティを追加
      for key, value in extensions {
        merged[key] = value
      }
      
      @json.JsonValue::Object(merged)
    }
    _ => base_schema
  }
}

// JSON Schema標準型のヘルパー
pub fn standard_string() -> @json.JsonValue {
  let obj = Map::new()
  obj["type"] = @json.JsonValue::String("string")
  @json.JsonValue::Object(obj)
}

pub fn standard_number() -> @json.JsonValue {
  let obj = Map::new()
  obj["type"] = @json.JsonValue::String("number")
  @json.JsonValue::Object(obj)
}

pub fn standard_boolean() -> @json.JsonValue {
  let obj = Map::new()
  obj["type"] = @json.JsonValue::String("boolean")
  @json.JsonValue::Object(obj)
}

pub fn standard_null() -> @json.JsonValue {
  let obj = Map::new()
  obj["type"] = @json.JsonValue::String("null")
  @json.JsonValue::Object(obj)
}

pub fn standard_array(items : @json.JsonValue) -> @json.JsonValue {
  let obj = Map::new()
  obj["type"] = @json.JsonValue::String("array")
  obj["items"] = items
  @json.JsonValue::Object(obj)
}

pub fn standard_object(
  properties : Map[String, @json.JsonValue],
  required : Array[String]?
) -> @json.JsonValue {
  let obj = Map::new()
  obj["type"] = @json.JsonValue::String("object")
  obj["properties"] = @json.JsonValue::Object(properties)
  
  match required {
    Some(req) => {
      let req_values = req.map(fn(r) { @json.JsonValue::String(r) })
      obj["required"] = @json.JsonValue::Array(req_values)
    }
    None => ()
  }
  
  @json.JsonValue::Object(obj)
}

// Union型 (anyOf)
pub fn standard_union(schemas : Array[@json.JsonValue]) -> @json.JsonValue {
  let obj = Map::new()
  obj["anyOf"] = @json.JsonValue::Array(schemas)
  @json.JsonValue::Object(obj)
}

// Intersection型 (allOf)
pub fn standard_intersection(schemas : Array[@json.JsonValue]) -> @json.JsonValue {
  let obj = Map::new()
  obj["allOf"] = @json.JsonValue::Array(schemas)
  @json.JsonValue::Object(obj)
}