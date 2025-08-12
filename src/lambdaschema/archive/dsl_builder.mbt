// MoonBitのDSLでJSON Schema拡張を組み立てる

// スキーマビルダー - JSON表現を組み立てる
pub struct SchemaBuilder {
  mut current : @json.JsonValue
}

pub fn SchemaBuilder::new() -> SchemaBuilder {
  {
    current: @json.JsonValue::Object(Map::new())
  }
}

// 基本型
pub fn string(self : SchemaBuilder) -> SchemaBuilder {
  self.current = standard_string()
  self
}

pub fn number(self : SchemaBuilder) -> SchemaBuilder {
  self.current = standard_number()
  self
}

pub fn boolean(self : SchemaBuilder) -> SchemaBuilder {
  self.current = standard_boolean()
  self
}

pub fn null(self : SchemaBuilder) -> SchemaBuilder {
  self.current = standard_null()
  self
}

// 複合型
pub fn array(self : SchemaBuilder, items : SchemaBuilder) -> SchemaBuilder {
  self.current = standard_array(items.current)
  self
}

pub fn object(
  self : SchemaBuilder,
  props : Array[(String, SchemaBuilder)]
) -> SchemaBuilder {
  let properties = Map::new()
  let required = Array::new()
  
  for (name, builder) in props {
    properties[name] = builder.current
    required.push(name)
  }
  
  self.current = standard_object(properties, Some(required))
  self
}

pub fn union(self : SchemaBuilder, schemas : Array[SchemaBuilder]) -> SchemaBuilder {
  let values = schemas.map(fn(s) { s.current })
  self.current = standard_union(values)
  self
}

// 拡張型 - 関数
pub fn function(
  self : SchemaBuilder,
  params : Array[(String, SchemaBuilder, Bool)],
  returns : SchemaBuilder
) -> SchemaBuilder {
  let param_array = Array::new()
  
  for (name, type_builder, optional) in params {
    let param_obj = Map::new()
    param_obj["name"] = @json.JsonValue::String(name)
    param_obj["type"] = type_builder.current
    param_obj["optional"] = @json.JsonValue::from_bool(optional)
    param_array.push(@json.JsonValue::Object(param_obj))
  }
  
  self.current = function_schema_json(
    param_array,
    returns.current,
    None,
    None,
    None
  )
  self
}

pub fn function_throws(
  self : SchemaBuilder,
  params : Array[(String, SchemaBuilder, Bool)],
  returns : SchemaBuilder,
  throws : SchemaBuilder
) -> SchemaBuilder {
  let param_array = Array::new()
  
  for (name, type_builder, optional) in params {
    let param_obj = Map::new()
    param_obj["name"] = @json.JsonValue::String(name)
    param_obj["type"] = type_builder.current
    param_obj["optional"] = @json.JsonValue::from_bool(optional)
    param_array.push(@json.JsonValue::Object(param_obj))
  }
  
  self.current = function_schema_json(
    param_array,
    returns.current,
    Some(throws.current),
    None,
    None
  )
  self
}

// ジェネリック関数
pub fn generic_function(
  self : SchemaBuilder,
  type_params : Array[String],
  params : Array[(String, SchemaBuilder, Bool)],
  returns : SchemaBuilder
) -> SchemaBuilder {
  let param_array = Array::new()
  
  for (name, type_builder, optional) in params {
    let param_obj = Map::new()
    param_obj["name"] = @json.JsonValue::String(name)
    param_obj["type"] = type_builder.current
    param_obj["optional"] = @json.JsonValue::from_bool(optional)
    param_array.push(@json.JsonValue::Object(param_obj))
  }
  
  self.current = function_schema_json(
    param_array,
    returns.current,
    None,
    Some(type_params),
    None
  )
  self
}

// 非同期型
pub fn promise(self : SchemaBuilder, resolves : SchemaBuilder) -> SchemaBuilder {
  self.current = async_schema_json("Promise", resolves.current)
  self
}

pub fn future(self : SchemaBuilder, resolves : SchemaBuilder) -> SchemaBuilder {
  self.current = async_schema_json("Future", resolves.current)
  self
}

// Result型
pub fn result(
  self : SchemaBuilder,
  ok : SchemaBuilder,
  error : SchemaBuilder
) -> SchemaBuilder {
  self.current = result_schema_json(ok.current, error.current)
  self
}

// Effect型
pub fn effect(
  self : SchemaBuilder,
  effect_name : String,
  value : SchemaBuilder,
  effects : Array[String]
) -> SchemaBuilder {
  self.current = effect_schema_json(effect_name, value.current, effects)
  self
}

// 型パラメータ
pub fn type_param(self : SchemaBuilder, name : String) -> SchemaBuilder {
  self.current = type_param_json(name, None)
  self
}

pub fn type_param_with_constraint(
  self : SchemaBuilder,
  name : String,
  constraint : SchemaBuilder
) -> SchemaBuilder {
  self.current = type_param_json(name, Some(constraint.current))
  self
}

// 参照
pub fn ref(self : SchemaBuilder, path : String) -> SchemaBuilder {
  let obj = Map::new()
  obj["$ref"] = @json.JsonValue::String(path)
  self.current = @json.JsonValue::Object(obj)
  self
}

pub fn ref_with_args(
  self : SchemaBuilder,
  path : String,
  args : Array[SchemaBuilder]
) -> SchemaBuilder {
  let arg_values = args.map(fn(a) { a.current })
  self.current = ref_with_args_json(path, Some(arg_values))
  self
}

// 高階型
pub fn higher_kinded(
  self : SchemaBuilder,
  name : String,
  kind : String
) -> SchemaBuilder {
  self.current = higher_kinded_json(name, kind, None)
  self
}

pub fn apply_type(
  self : SchemaBuilder,
  ctor : SchemaBuilder,
  args : Array[SchemaBuilder]
) -> SchemaBuilder {
  match ctor.current {
    @json.JsonValue::Object(obj) => {
      match obj.get("$higherKinded") {
        Some(@json.JsonValue::String(name)) => {
          match obj.get("$kind") {
            Some(@json.JsonValue::String(kind)) => {
              let arg_values = args.map(fn(a) { a.current })
              self.current = higher_kinded_json(name, kind, Some(arg_values))
            }
            _ => self.current = ctor.current
          }
        }
        _ => self.current = ctor.current
      }
    }
    _ => self.current = ctor.current
  }
  self
}

// ビルド結果を取得
pub fn build(self : SchemaBuilder) -> @json.JsonValue {
  self.current
}

// ヘルパー関数でビルダーを作成
pub fn schema() -> SchemaBuilder {
  SchemaBuilder::new()
}

// 使用例を作成する関数
pub fn example_rpc_schema() -> @json.JsonValue {
  // map<T, U>: (T -> U) -> Array<T> -> Array<U>
  let map_function = schema().generic_function(
    ["T", "U"],
    [
      ("mapper", schema().function(
        [("value", schema().type_param("T"), false)],
        schema().type_param("U")
      ), false),
      ("array", schema().array(schema().type_param("T")), false)
    ],
    schema().array(schema().type_param("U"))
  ).build()
  
  // getUserAsync: (id: string) -> Promise<User>
  let get_user_async = schema().function(
    [("id", schema().string(), false)],
    schema().promise(schema().ref("#/definitions/User"))
  ).build()
  
  // trySave: (data: T) -> Result<T, Error>
  let try_save = schema().generic_function(
    ["T"],
    [("data", schema().type_param("T"), false)],
    schema().result(
      schema().type_param("T"),
      schema().ref("#/definitions/Error")
    )
  ).build()
  
  // withIO: () -> Effect<IO, string>
  let with_io = schema().function(
    [],
    schema().effect("IO", schema().string(), ["read", "write"])
  ).build()
  
  // compose: <A, B, C>((B -> C), (A -> B)) -> (A -> C)
  let compose = schema().generic_function(
    ["A", "B", "C"],
    [
      ("f", schema().function(
        [("x", schema().type_param("B"), false)],
        schema().type_param("C")
      ), false),
      ("g", schema().function(
        [("x", schema().type_param("A"), false)],
        schema().type_param("B")
      ), false)
    ],
    schema().function(
      [("x", schema().type_param("A"), false)],
      schema().type_param("C")
    )
  ).build()
  
  // サービス定義として統合
  let service = Map::new()
  service["version"] = @json.JsonValue::String("1.0.0")
  service["functions"] = @json.JsonValue::Object({
    let funcs = Map::new()
    funcs["map"] = map_function
    funcs["getUserAsync"] = get_user_async
    funcs["trySave"] = try_save
    funcs["withIO"] = with_io
    funcs["compose"] = compose
    funcs
  })
  
  @json.JsonValue::Object(service)
}