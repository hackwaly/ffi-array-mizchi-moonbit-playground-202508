// TypeScript型シグネチャを表現するJSON Schema拡張

// 関数型のJSON Schema表現
// {
//   "type": "function",
//   "typeParameters": [
//     {"name": "T", "constraint": {"extends": {...}}}
//   ],
//   "parameters": [
//     {"name": "x", "type": {...}, "optional": false}
//   ],
//   "returns": {...},
//   "throws": {...}
// }
pub fn ts_function_schema(
  parameters : Array[Json],
  returns : Json,
  throws : Json?,
  type_parameters : Array[Json]?
) -> Json {
  let obj : Map[String, Json] = {}
  
  // 関数型識別子
  obj["type"] = Json::string("function")
  
  // パラメータ
  obj["parameters"] = Json::array(parameters)
  
  // 戻り値
  obj["returns"] = returns
  
  // 例外
  match throws {
    Some(t) => obj["throws"] = t
    None => ()
  }
  
  // 型パラメータ
  match type_parameters {
    Some(tp) => obj["typeParameters"] = Json::array(tp)
    None => ()
  }
  
  Json::object(obj)
}

// 型パラメータの表現（T extends Constraint）
// {
//   "name": "T",
//   "constraint": {
//     "extends": {...},
//     "default": {...}
//   }
// }
pub fn ts_type_parameter(
  name : String,
  extends : Json?,
  default : Json?
) -> Json {
  let obj : Map[String, Json] = {}
  obj["name"] = Json::string(name)
  
  if extends.is_some() || default.is_some() {
    let constraint : Map[String, Json] = {}
    match extends {
      Some(e) => constraint["extends"] = e
      None => ()
    }
    match default {
      Some(d) => constraint["default"] = d
      None => ()
    }
    obj["constraint"] = Json::object(constraint)
  }
  
  Json::object(obj)
}

// 型参照（型パラメータの使用）
// {
//   "type": "typeParameter",
//   "name": "T"
// }
pub fn ts_type_param_ref(name : String) -> Json {
  let obj : Map[String, Json] = {}
  obj["type"] = Json::string("typeParameter")
  obj["name"] = Json::string(name)
  Json::object(obj)
}

// ジェネリック型の適用（Array<T>）
// {
//   "type": "generic",
//   "base": "Array",
//   "typeArguments": [{...}]
// }
pub fn ts_generic_type(
  base : String,
  type_arguments : Array[Json]
) -> Json {
  let obj : Map[String, Json] = {}
  obj["type"] = Json::string("generic")
  obj["base"] = Json::string(base)
  obj["typeArguments"] = Json::array(type_arguments)
  Json::object(obj)
}

// Promise型
// {
//   "type": "promise",
//   "resolves": {...}
// }
pub fn ts_promise(resolves : Json) -> Json {
  let obj : Map[String, Json] = {}
  obj["type"] = Json::string("promise")
  obj["resolves"] = resolves
  Json::object(obj)
}

// Async関数
// {
//   "type": "async-function",
//   "parameters": [...],
//   "returns": {...}
// }
pub fn ts_async_function(
  parameters : Array[Json],
  returns : Json,
  type_parameters : Array[Json]?
) -> Json {
  let obj : Map[String, Json] = {}
  obj["type"] = Json::string("async-function")
  obj["parameters"] = Json::array(parameters)
  obj["returns"] = returns
  
  match type_parameters {
    Some(tp) => obj["typeParameters"] = Json::array(tp)
    None => ()
  }
  
  Json::object(obj)
}

// Conditional型（T extends U ? X : Y）
// {
//   "type": "conditional",
//   "check": {...},
//   "extends": {...},
//   "trueType": {...},
//   "falseType": {...}
// }
pub fn ts_conditional(
  check : Json,
  extends_type : Json,
  true_type : Json,
  false_type : Json
) -> Json {
  let obj : Map[String, Json] = {}
  obj["type"] = Json::string("conditional")
  obj["check"] = check
  obj["extends"] = extends_type
  obj["trueType"] = true_type
  obj["falseType"] = false_type
  Json::object(obj)
}

// Mapped型（{ [K in T]: U }）
// {
//   "type": "mapped",
//   "parameter": "K",
//   "constraint": {...},
//   "template": {...},
//   "optional": "?",
//   "readonly": true
// }
pub fn ts_mapped_type(
  parameter : String,
  constraint : Json,
  template : Json,
  optional : String?,
  is_readonly : Bool?
) -> Json {
  let obj : Map[String, Json] = {}
  obj["type"] = Json::string("mapped")
  obj["parameter"] = Json::string(parameter)
  obj["constraint"] = constraint
  obj["template"] = template
  
  match optional {
    Some(opt) => obj["optional"] = Json::string(opt)
    None => ()
  }
  
  match is_readonly {
    Some(r) => obj["readonly"] = Json::boolean(r)
    None => ()
  }
  
  Json::object(obj)
}

// Template Literal型
// {
//   "type": "template-literal",
//   "parts": [
//     {"type": "literal", "value": "Hello, "},
//     {"type": "interpolation", "value": {...}}
//   ]
// }
pub fn ts_template_literal(parts : Array[Json]) -> Json {
  let obj : Map[String, Json] = {}
  obj["type"] = Json::string("template-literal")
  obj["parts"] = Json::array(parts)
  Json::object(obj)
}

// Keyof型
// {
//   "type": "keyof",
//   "target": {...}
// }
pub fn ts_keyof(target : Json) -> Json {
  let obj : Map[String, Json] = {}
  obj["type"] = Json::string("keyof")
  obj["target"] = target
  Json::object(obj)
}

// Typeof型
// {
//   "type": "typeof",
//   "target": "variableName"
// }
pub fn ts_typeof(target : String) -> Json {
  let obj : Map[String, Json] = {}
  obj["type"] = Json::string("typeof")
  obj["target"] = Json::string(target)
  Json::object(obj)
}

// Indexed Access型（T[K]）
// {
//   "type": "indexed-access",
//   "object": {...},
//   "index": {...}
// }
pub fn ts_indexed_access(
  object_type : Json,
  index_type : Json
) -> Json {
  let obj : Map[String, Json] = {}
  obj["type"] = Json::string("indexed-access")
  obj["object"] = object_type
  obj["index"] = index_type
  Json::object(obj)
}

// Infer型（infer R）
// {
//   "type": "infer",
//   "name": "R"
// }
pub fn ts_infer(name : String) -> Json {
  let obj : Map[String, Json] = {}
  obj["type"] = Json::string("infer")
  obj["name"] = Json::string(name)
  Json::object(obj)
}

// Utility型（Partial, Required, Readonly等）
// {
//   "type": "utility",
//   "name": "Partial",
//   "typeArguments": [{...}]
// }
pub fn ts_utility_type(
  name : String,
  type_arguments : Array[Json]
) -> Json {
  let obj : Map[String, Json] = {}
  obj["type"] = Json::string("utility")
  obj["name"] = Json::string(name)
  obj["typeArguments"] = Json::array(type_arguments)
  Json::object(obj)
}

// Tuple型
// {
//   "type": "tuple",
//   "elements": [...],
//   "rest": {...}
// }
pub fn ts_tuple(
  elements : Array[Json],
  rest : Json?
) -> Json {
  let obj : Map[String, Json] = {}
  obj["type"] = Json::string("tuple")
  obj["elements"] = Json::array(elements)
  
  match rest {
    Some(r) => obj["rest"] = r
    None => ()
  }
  
  Json::object(obj)
}

// 標準的な基本型
pub fn ts_string() -> Json {
  Json::object(Map::of([("type", Json::string("string"))]))
}

pub fn ts_number() -> Json {
  Json::object(Map::of([("type", Json::string("number"))]))
}

pub fn ts_boolean() -> Json {
  Json::object(Map::of([("type", Json::string("boolean"))]))
}

pub fn ts_null() -> Json {
  Json::object(Map::of([("type", Json::string("null"))]))
}

pub fn ts_undefined() -> Json {
  Json::object(Map::of([("type", Json::string("undefined"))]))
}

pub fn ts_unknown() -> Json {
  Json::object(Map::of([("type", Json::string("unknown"))]))
}

pub fn ts_any() -> Json {
  Json::object(Map::of([("type", Json::string("any"))]))
}

pub fn ts_never() -> Json {
  Json::object(Map::of([("type", Json::string("never"))]))
}

pub fn ts_void() -> Json {
  Json::object(Map::of([("type", Json::string("void"))]))
}