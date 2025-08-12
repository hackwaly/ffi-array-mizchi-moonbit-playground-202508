// TypeScript型表現のためのMoonBit DSL

pub struct TsBuilder {
  mut current : Json
}

pub fn TsBuilder::new() -> TsBuilder {
  {
    current: Json::object({})
  }
}

// 基本型
pub fn string(self : TsBuilder) -> TsBuilder {
  self.current = ts_string()
  self
}

pub fn number(self : TsBuilder) -> TsBuilder {
  self.current = ts_number()
  self
}

pub fn boolean(self : TsBuilder) -> TsBuilder {
  self.current = ts_boolean()
  self
}

pub fn null(self : TsBuilder) -> TsBuilder {
  self.current = ts_null()
  self
}

pub fn undefined(self : TsBuilder) -> TsBuilder {
  self.current = ts_undefined()
  self
}

pub fn unknown(self : TsBuilder) -> TsBuilder {
  self.current = ts_unknown()
  self
}

pub fn any(self : TsBuilder) -> TsBuilder {
  self.current = ts_any()
  self
}

pub fn never(self : TsBuilder) -> TsBuilder {
  self.current = ts_never()
  self
}

pub fn void_type(self : TsBuilder) -> TsBuilder {
  self.current = ts_void()
  self
}

// ジェネリック型
pub fn array(self : TsBuilder, element : TsBuilder) -> TsBuilder {
  self.current = ts_generic_type("Array", [element.current])
  self
}

pub fn promise(self : TsBuilder, resolves : TsBuilder) -> TsBuilder {
  self.current = ts_promise(resolves.current)
  self
}

pub fn record(self : TsBuilder, key : TsBuilder, value : TsBuilder) -> TsBuilder {
  self.current = ts_generic_type("Record", [key.current, value.current])
  self
}

pub fn map(self : TsBuilder, key : TsBuilder, value : TsBuilder) -> TsBuilder {
  self.current = ts_generic_type("Map", [key.current, value.current])
  self
}

pub fn set(self : TsBuilder, element : TsBuilder) -> TsBuilder {
  self.current = ts_generic_type("Set", [element.current])
  self
}

// タプル型
pub fn tuple(self : TsBuilder, elements : Array[TsBuilder]) -> TsBuilder {
  let element_jsons = elements.map(fn(e) { e.current })
  self.current = ts_tuple(element_jsons, None)
  self
}

pub fn tuple_with_rest(
  self : TsBuilder,
  elements : Array[TsBuilder],
  rest : TsBuilder
) -> TsBuilder {
  let element_jsons = elements.map(fn(e) { e.current })
  self.current = ts_tuple(element_jsons, Some(rest.current))
  self
}

// 型パラメータ
pub fn type_param(self : TsBuilder, name : String) -> TsBuilder {
  self.current = ts_type_param_ref(name)
  self
}

// 関数型（TypeScript風）
pub fn func(
  self : TsBuilder,
  params : Array[(String, TsBuilder, Bool)],
  returns : TsBuilder
) -> TsBuilder {
  let param_array = Array::new()
  
  for param in params {
    let (name, type_builder, optional) = param
    let param_obj : Map[String, Json] = {}
    param_obj["name"] = Json::string(name)
    param_obj["type"] = type_builder.current
    param_obj["optional"] = Json::boolean(optional)
    param_array.push(Json::object(param_obj))
  }
  
  self.current = ts_function_schema(
    param_array,
    returns.current,
    None,
    None
  )
  self
}

// ジェネリック関数（T extends Constraint付き）
pub fn generic_func(
  self : TsBuilder,
  type_params : Array[(String, TsBuilder?, TsBuilder?)], // (name, extends?, default?)
  params : Array[(String, TsBuilder, Bool)],
  returns : TsBuilder
) -> TsBuilder {
  // 型パラメータの構築
  let type_param_array = Array::new()
  for type_param in type_params {
    let (name, extends, default) = type_param
    let extends_json = match extends {
      Some(e) => Some(e.current)
      None => None
    }
    let default_json = match default {
      Some(d) => Some(d.current)
      None => None
    }
    type_param_array.push(ts_type_parameter(name, extends_json, default_json))
  }
  
  // 関数パラメータの構築
  let param_array = Array::new()
  for param in params {
    let (name, type_builder, optional) = param
    let param_obj : Map[String, Json] = {}
    param_obj["name"] = Json::string(name)
    param_obj["type"] = type_builder.current
    param_obj["optional"] = Json::boolean(optional)
    param_array.push(Json::object(param_obj))
  }
  
  self.current = ts_function_schema(
    param_array,
    returns.current,
    None,
    Some(type_param_array)
  )
  self
}

// async関数
pub fn async_func(
  self : TsBuilder,
  params : Array[(String, TsBuilder, Bool)],
  returns : TsBuilder
) -> TsBuilder {
  let param_array = Array::new()
  
  for param in params {
    let (name, type_builder, optional) = param
    let param_obj : Map[String, Json] = {}
    param_obj["name"] = Json::string(name)
    param_obj["type"] = type_builder.current
    param_obj["optional"] = Json::boolean(optional)
    param_array.push(Json::object(param_obj))
  }
  
  self.current = ts_async_function(
    param_array,
    returns.current,
    None
  )
  self
}

// Conditional型
pub fn conditional(
  self : TsBuilder,
  check : TsBuilder,
  extends : TsBuilder,
  true_type : TsBuilder,
  false_type : TsBuilder
) -> TsBuilder {
  self.current = ts_conditional(
    check.current,
    extends.current,
    true_type.current,
    false_type.current
  )
  self
}

// Utility型
pub fn partial(self : TsBuilder, target : TsBuilder) -> TsBuilder {
  self.current = ts_utility_type("Partial", [target.current])
  self
}

pub fn required(self : TsBuilder, target : TsBuilder) -> TsBuilder {
  self.current = ts_utility_type("Required", [target.current])
  self
}

pub fn make_readonly(self : TsBuilder, target : TsBuilder) -> TsBuilder {
  self.current = ts_utility_type("Readonly", [target.current])
  self
}

pub fn pick(self : TsBuilder, target : TsBuilder, keys : TsBuilder) -> TsBuilder {
  self.current = ts_utility_type("Pick", [target.current, keys.current])
  self
}

pub fn omit(self : TsBuilder, target : TsBuilder, keys : TsBuilder) -> TsBuilder {
  self.current = ts_utility_type("Omit", [target.current, keys.current])
  self
}

// keyof型
pub fn keyof(self : TsBuilder, target : TsBuilder) -> TsBuilder {
  self.current = ts_keyof(target.current)
  self
}

// typeof型
pub fn type_of(self : TsBuilder, variable : String) -> TsBuilder {
  self.current = ts_typeof(variable)
  self
}

// Indexed Access型
pub fn index(self : TsBuilder, object : TsBuilder, key : TsBuilder) -> TsBuilder {
  self.current = ts_indexed_access(object.current, key.current)
  self
}

// ビルド
pub fn build(self : TsBuilder) -> Json {
  self.current
}

// ヘルパー関数
pub fn ts() -> TsBuilder {
  TsBuilder::new()
}

// 使用例
pub fn example_typescript_types() -> Json {
  let examples : Map[String, Json] = {}
  
  // 1. identity<T>(x: T): T
  examples["identity"] = ts().generic_func(
    [("T", None, None)],
    [("x", ts().type_param("T"), false)],
    ts().type_param("T")
  ).build()
  
  // 2. map<T, U>(array: T[], fn: (value: T) => U): U[]
  examples["map"] = ts().generic_func(
    [("T", None, None), ("U", None, None)],
    [
      ("array", ts().array(ts().type_param("T")), false),
      ("fn", ts().func(
        [("value", ts().type_param("T"), false)],
        ts().type_param("U")
      ), false)
    ],
    ts().array(ts().type_param("U"))
  ).build()
  
  // 3. filter<T extends object>(items: T[]): T[]
  examples["filter"] = ts().generic_func(
    [("T", Some(ts().unknown()), None)], // T extends unknown (simplified)
    [("items", ts().array(ts().type_param("T")), false)],
    ts().array(ts().type_param("T"))
  ).build()
  
  // 4. async fetchUser(id: string): Promise<User>
  examples["fetchUser"] = ts().async_func(
    [("id", ts().string(), false)],
    ts().record(ts().string(), ts().any()) // simplified User type
  ).build()
  
  // 5. compose<A, B, C>(f: (b: B) => C, g: (a: A) => B): (a: A) => C
  examples["compose"] = ts().generic_func(
    [("A", None, None), ("B", None, None), ("C", None, None)],
    [
      ("f", ts().func(
        [("b", ts().type_param("B"), false)],
        ts().type_param("C")
      ), false),
      ("g", ts().func(
        [("a", ts().type_param("A"), false)],
        ts().type_param("B")
      ), false)
    ],
    ts().func(
      [("a", ts().type_param("A"), false)],
      ts().type_param("C")
    )
  ).build()
  
  // 6. Conditional型: T extends string ? number : boolean
  examples["conditional"] = ts().conditional(
    ts().type_param("T"),
    ts().string(),
    ts().number(),
    ts().boolean()
  ).build()
  
  // 7. Partial<User>
  examples["partialUser"] = ts().partial(
    ts().record(ts().string(), ts().any())
  ).build()
  
  // 8. Pick<User, "id" | "name">
  examples["pickUser"] = ts().pick(
    ts().record(ts().string(), ts().any()),
    ts().string() // simplified union of literals
  ).build()
  
  Json::object(examples)
}

// TypeScript RPC定義の例
pub fn example_rpc_service() -> Json {
  let service : Map[String, Json] = {}
  service["name"] = Json::string("UserService")
  service["version"] = Json::string("1.0.0")
  
  let methods : Map[String, Json] = {}
  
  // getUser(id: string): Promise<User | null>
  methods["getUser"] = ts().func(
    [("id", ts().string(), false)],
    ts().promise(
      ts().record(ts().string(), ts().any()) // simplified User type
    )
  ).build()
  
  // createUser<T extends UserInput>(data: T): Promise<User>
  methods["createUser"] = ts().generic_func(
    [("T", Some(ts().record(ts().string(), ts().any())), None)],
    [("data", ts().type_param("T"), false)],
    ts().promise(
      ts().record(ts().string(), ts().any())
    )
  ).build()
  
  // updateUser(id: string, data: Partial<User>): Promise<User>
  methods["updateUser"] = ts().func(
    [
      ("id", ts().string(), false),
      ("data", ts().partial(ts().record(ts().string(), ts().any())), false)
    ],
    ts().promise(
      ts().record(ts().string(), ts().any())
    )
  ).build()
  
  service["methods"] = Json::object(methods)
  
  Json::object(service)
}