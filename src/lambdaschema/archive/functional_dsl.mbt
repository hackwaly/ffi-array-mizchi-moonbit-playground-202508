// 関数型スタイルのRPC定義DSL

// 型エイリアスを定義して簡潔に
pub typealias Schema = @jsonschema/types.Schema
pub typealias JsonValue = @json.JsonValue

// RPC定義を関数型スタイルで記述
pub fn define_service(
  name : String,
  version : String,
  definitions : (ServiceBuilder) -> ServiceBuilder
) -> RpcService {
  let builder = ServiceBuilder::new(name, version)
  definitions(builder).build()
}

// サービスビルダー
pub struct ServiceBuilder {
  name : String
  version : String
  mut functions : Map[String, RpcFunction]
  mut types : Map[String, Schema]
}

pub fn ServiceBuilder::new(name : String, version : String) -> ServiceBuilder {
  {
    name: name,
    version: version,
    functions: Map::new(),
    types: Map::new()
  }
}

// 関数定義を追加（関数型スタイル）
pub fn function(
  self : ServiceBuilder,
  name : String,
  spec : FunctionSpec
) -> ServiceBuilder {
  self.functions[name] = spec.to_rpc_function(name)
  self
}

// 型定義を追加
pub fn typedef(
  self : ServiceBuilder,
  name : String,
  schema : Schema
) -> ServiceBuilder {
  self.types[name] = schema
  self
}

pub fn build(self : ServiceBuilder) -> RpcService {
  {
    name: self.name,
    version: self.version,
    functions: self.functions,
    types: self.types
  }
}

// 関数仕様を関数型スタイルで定義
pub struct FunctionSpec {
  params : Array[(String, Schema, Bool)]  // (name, type, required)
  returns : Schema
  throws : Schema?
  description : String?
}

// 関数定義のヘルパー関数
pub fn func(
  params : Array[(String, Schema)],
  returns : Schema
) -> FunctionSpec {
  {
    params: params.map(fn((name, schema)) { (name, schema, true) }),
    returns: returns,
    throws: None,
    description: None
  }
}

// オプショナルパラメータ付き関数
pub fn func_with_optional(
  params : Array[(String, Schema, Bool)],
  returns : Schema
) -> FunctionSpec {
  {
    params: params,
    returns: returns,
    throws: None,
    description: None
  }
}

// 例外付き関数
pub fn func_throws(
  params : Array[(String, Schema)],
  returns : Schema,
  throws : Schema
) -> FunctionSpec {
  {
    params: params.map(fn((name, schema)) { (name, schema, true) }),
    returns: returns,
    throws: Some(throws),
    description: None
  }
}

// 説明付き
pub fn with_description(self : FunctionSpec, desc : String) -> FunctionSpec {
  { ..self, description: Some(desc) }
}

// FunctionSpecをRpcFunctionに変換
fn to_rpc_function(self : FunctionSpec, name : String) -> RpcFunction {
  // パラメータをスキーマに変換
  let param_schemas = self.params.map(fn((_, schema, _)) { schema })
  let param_names = self.params.map(fn((name, _, _)) { name })
  let required_params = Array::new()
  
  for i, (name, _, is_required) in self.params {
    if is_required {
      required_params.push(name)
    }
  }
  
  // パラメータオブジェクトスキーマを作成
  let param_props = Map::new()
  for (name, schema, _) in self.params {
    param_props[name] = schema
  }
  
  let parameters = if param_props.is_empty() {
    Schema::Object({
      properties: Some(Map::new()),
      required: None,
      additional_properties: Some(Schema::Boolean),
      pattern_properties: None,
      property_names: None,
      dependent_schemas: None,
      dependent_required: None,
      min_properties: None,
      max_properties: None
    })
  } else {
    Schema::Object({
      properties: Some(param_props),
      required: if required_params.is_empty() { None } else { Some(required_params) },
      additional_properties: Some(Schema::Boolean),
      pattern_properties: None,
      property_names: None,
      dependent_schemas: None,
      dependent_required: None,
      min_properties: None,
      max_properties: None
    })
  }
  
  {
    name: name,
    description: self.description,
    parameters: parameters,
    returns: self.returns,
    throws: self.throws,
    metadata: Map::new()
  }
}

// 型定義ヘルパー関数
pub fn string() -> Schema {
  Schema::String({
    min_length: None,
    max_length: None,
    pattern: None,
    format: None,
    content_encoding: None,
    content_media_type: None
  })
}

pub fn number() -> Schema {
  Schema::Number({
    minimum: None,
    maximum: None,
    exclusive_minimum: None,
    exclusive_maximum: None,
    multiple_of: None
  })
}

pub fn boolean() -> Schema {
  Schema::Boolean
}

pub fn array(item : Schema) -> Schema {
  Schema::Array({
    items: Some(item),
    prefix_items: None,
    contains: None,
    min_contains: None,
    max_contains: None,
    min_items: None,
    max_items: None,
    unique_items: None
  })
}

pub fn object(properties : Array[(String, Schema)]) -> Schema {
  let props = Map::new()
  let required = Array::new()
  
  for (name, schema) in properties {
    props[name] = schema
    required.push(name)
  }
  
  Schema::Object({
    properties: Some(props),
    required: if required.is_empty() { None } else { Some(required) },
    additional_properties: Some(Schema::Boolean),
    pattern_properties: None,
    property_names: None,
    dependent_schemas: None,
    dependent_required: None,
    min_properties: None,
    max_properties: None
  })
}

pub fn optional(schema : Schema) -> Schema {
  Schema::AnyOfSchemas([schema, Schema::Null])
}

pub fn union(schemas : Array[Schema]) -> Schema {
  Schema::AnyOfSchemas(schemas)
}

pub fn ref(name : String) -> Schema {
  Schema::Ref("#/definitions/" + name)
}

// 使用例を作成する関数
pub fn create_example_service() -> RpcService {
  define_service("UserService", "1.0.0", fn(service) {
    service
      // 型定義
      .typedef("User", object([
        ("id", string()),
        ("name", string()),
        ("email", string()),
        ("age", optional(number()))
      ]))
      .typedef("Error", object([
        ("code", string()),
        ("message", string())
      ]))
      
      // 関数定義（関数型スタイル）
      .function("getUser",
        func(
          [("id", string())],
          ref("User")
        ).with_description("Get user by ID")
      )
      
      .function("createUser", 
        func_throws(
          [
            ("name", string()),
            ("email", string())
          ],
          ref("User"),
          ref("Error")
        ).with_description("Create a new user")
      )
      
      .function("updateUser",
        func_with_optional(
          [
            ("id", string(), true),
            ("name", string(), false),
            ("email", string(), false)
          ],
          ref("User")
        ).with_description("Update user information")
      )
      
      .function("listUsers",
        func(
          [
            ("limit", optional(number())),
            ("offset", optional(number()))
          ],
          array(ref("User"))
        ).with_description("List all users with pagination")
      )
      
      .function("searchUsers",
        func(
          [("query", string())],
          array(ref("User"))
        ).with_description("Search users by query")
      )
  })
}

// 関数合成のヘルパー
pub fn compose_specs(
  f1 : FunctionSpec,
  f2 : FunctionSpec
) -> FunctionSpec? {
  // f1の戻り値がf2の最初のパラメータと互換性があるかチェック
  if f2.params.is_empty() {
    return None
  }
  
  let (_, f2_first_param, _) = f2.params[0]
  
  // 簡単な互換性チェック（実際にはもっと複雑）
  if f1.returns == f2_first_param {
    // 残りのf2パラメータとf1パラメータを結合
    let mut new_params = f1.params.copy()
    for i in 1..<f2.params.length() {
      new_params.push(f2.params[i])
    }
    
    Some({
      params: new_params,
      returns: f2.returns,
      throws: match (f1.throws, f2.throws) {
        (None, None) => None
        (Some(t), None) | (None, Some(t)) => Some(t)
        (Some(t1), Some(t2)) => Some(union([t1, t2]))
      },
      description: None
    })
  } else {
    None
  }
}

// パイプライン演算子風の関数合成
pub fn pipe(specs : Array[FunctionSpec]) -> FunctionSpec? {
  if specs.is_empty() {
    return None
  }
  
  let mut result = specs[0]
  for i in 1..<specs.length() {
    match compose_specs(result, specs[i]) {
      Some(composed) => result = composed
      None => return None
    }
  }
  
  Some(result)
}