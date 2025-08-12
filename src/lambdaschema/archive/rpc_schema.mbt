// RPC定義用のJSON Schema拡張DSL

// RPC関数定義
pub struct RpcFunction {
  name : String
  description : String?
  parameters : @jsonschema/types.Schema
  returns : @jsonschema/types.Schema
  throws : @jsonschema/types.Schema?
  metadata : Map[String, @json.JsonValue]
}

// RPC サービス定義
pub struct RpcService {
  name : String
  version : String
  functions : Map[String, RpcFunction]
  types : Map[String, @jsonschema/types.Schema]
}

// JSON SchemaからRPC関数定義を生成
pub fn RpcFunction::from_schema(schema : @jsonschema/types.Schema) -> RpcFunction? {
  match schema {
    Object(constraints) => {
      match constraints.properties {
        Some(props) => {
          // $functionプロパティを持つオブジェクトをRPC関数として認識
          match props.get("$function") {
            Some(@jsonschema/types.Schema::ConstValue(@json.JsonValue::True)) => {
              let name = match props.get("name") {
                Some(@jsonschema/types.Schema::ConstValue(@json.JsonValue::String(n))) => n
                _ => "anonymous"
              }
              
              let parameters = props.get("parameters").unwrap_or(@jsonschema/types.Schema::Any)
              let returns = props.get("returns").unwrap_or(@jsonschema/types.Schema::Any)
              let throws = props.get("throws")
              
              Some({
                name: name,
                description: None,
                parameters: parameters,
                returns: returns,
                throws: throws,
                metadata: Map::new()
              })
            }
            _ => None
          }
        }
        None => None
      }
    }
    _ => None
  }
}

// RPC関数定義をJSON Schemaに変換
pub fn to_schema(self : RpcFunction) -> @jsonschema/types.Schema {
  let properties = Map::new()
  
  // 関数マーカー
  properties["$function"] = @jsonschema/types.Schema::ConstValue(@json.JsonValue::True)
  
  // 関数名
  properties["name"] = @jsonschema/types.Schema::ConstValue(@json.JsonValue::String(self.name))
  
  // パラメータスキーマ
  properties["parameters"] = self.parameters
  
  // 戻り値スキーマ
  properties["returns"] = self.returns
  
  // 例外スキーマ
  match self.throws {
    Some(throws) => properties["throws"] = throws
    None => ()
  }
  
  // 説明
  match self.description {
    Some(desc) => properties["description"] = @jsonschema/types.Schema::ConstValue(@json.JsonValue::String(desc))
    None => ()
  }
  
  @jsonschema/types.Schema::Object({
    properties: Some(properties),
    required: Some(["$function", "name", "parameters", "returns"]),
    additional_properties: Some(@jsonschema/types.Schema::Boolean),
    pattern_properties: None,
    property_names: None,
    dependent_schemas: None,
    dependent_required: None,
    min_properties: None,
    max_properties: None
  })
}

// RPC関数定義を簡潔に作成するビルダー
pub struct RpcFunctionBuilder {
  mut name : String
  mut description : String?
  mut parameters : Array[@jsonschema/types.Schema]
  mut returns : @jsonschema/types.Schema
  mut throws : @jsonschema/types.Schema?
  mut metadata : Map[String, @json.JsonValue]
}

pub fn RpcFunctionBuilder::new(name : String) -> RpcFunctionBuilder {
  {
    name: name,
    description: None,
    parameters: Array::new(),
    returns: @jsonschema/types.Schema::Any,
    throws: None,
    metadata: Map::new()
  }
}

pub fn with_description(self : RpcFunctionBuilder, desc : String) -> RpcFunctionBuilder {
  self.description = Some(desc)
  self
}

pub fn with_parameter(
  self : RpcFunctionBuilder,
  name : String,
  schema : @jsonschema/types.Schema,
  required : Bool
) -> RpcFunctionBuilder {
  // パラメータをオブジェクトスキーマとして構築
  self.parameters.push(schema)
  self
}

pub fn with_returns(self : RpcFunctionBuilder, schema : @jsonschema/types.Schema) -> RpcFunctionBuilder {
  self.returns = schema
  self
}

pub fn with_throws(self : RpcFunctionBuilder, schema : @jsonschema/types.Schema) -> RpcFunctionBuilder {
  self.throws = Some(schema)
  self
}

pub fn build(self : RpcFunctionBuilder) -> RpcFunction {
  // パラメータ配列をオブジェクトスキーマに変換
  let params_schema = if self.parameters.is_empty() {
    @jsonschema/types.Schema::Object({
      properties: Some(Map::new()),
      required: None,
      additional_properties: Some(@jsonschema/types.Schema::Boolean),
      pattern_properties: None,
      property_names: None,
      dependent_schemas: None,
      dependent_required: None,
      min_properties: None,
      max_properties: None
    })
  } else {
    @jsonschema/types.Schema::Array({
      items: None,
      prefix_items: Some(self.parameters),
      contains: None,
      min_contains: None,
      max_contains: None,
      min_items: Some(self.parameters.length()),
      max_items: Some(self.parameters.length()),
      unique_items: None
    })
  }
  
  {
    name: self.name,
    description: self.description,
    parameters: params_schema,
    returns: self.returns,
    throws: self.throws,
    metadata: self.metadata
  }
}

// サンプルRPC定義の作成
pub fn create_sample_rpc_service() -> RpcService {
  let functions = Map::new()
  
  // getUserById関数
  let get_user = RpcFunctionBuilder::new("getUserById")
    .with_description("Get user information by ID")
    .with_parameter("id", @jsonschema/types.Schema::String(StringConstraints::default()), true)
    .with_returns(@jsonschema/types.Schema::Object({
      properties: Some({
        let props = Map::new()
        props["id"] = @jsonschema/types.Schema::String(StringConstraints::default())
        props["name"] = @jsonschema/types.Schema::String(StringConstraints::default())
        props["email"] = @jsonschema/types.Schema::String(StringConstraints::default())
        props
      }),
      required: Some(["id", "name", "email"]),
      additional_properties: Some(@jsonschema/types.Schema::Boolean),
      pattern_properties: None,
      property_names: None,
      dependent_schemas: None,
      dependent_required: None,
      min_properties: None,
      max_properties: None
    }))
    .with_throws(@jsonschema/types.Schema::Object({
      properties: Some({
        let props = Map::new()
        props["code"] = @jsonschema/types.Schema::String(StringConstraints::default())
        props["message"] = @jsonschema/types.Schema::String(StringConstraints::default())
        props
      }),
      required: Some(["code", "message"]),
      additional_properties: Some(@jsonschema/types.Schema::Boolean),
      pattern_properties: None,
      property_names: None,
      dependent_schemas: None,
      dependent_required: None,
      min_properties: None,
      max_properties: None
    }))
    .build()
  
  functions["getUserById"] = get_user
  
  {
    name: "UserService",
    version: "1.0.0",
    functions: functions,
    types: Map::new()
  }
}

// デフォルト値を持つ制約の生成
fn StringConstraints::default() -> @jsonschema/types.StringConstraints {
  {
    min_length: None,
    max_length: None,
    pattern: None,
    format: None,
    content_encoding: None,
    content_media_type: None
  }
}