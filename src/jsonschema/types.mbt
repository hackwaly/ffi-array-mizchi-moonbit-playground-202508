// JSON Schema types and definitions
// Using built-in @json.JsonValue instead of custom JsonValue type

///|
pub enum SchemaType {
  Null
  Boolean
  Number
  Integer
  String
  Array
  Object
} derive(Show)

// Schema as enum for context-aware validation

///|
pub enum Schema {
  // Basic types
  Null
  Boolean
  String(StringConstraints)
  Number(NumberConstraints)
  Integer(NumberConstraints)
  Array(ArrayConstraints)
  Object(ObjectConstraints)

  // Composite schemas
  EnumValues(Array[Json])
  ConstValue(Json)
  AnyOfSchemas(Array[Schema])
  AllOfSchemas(Array[Schema])
  OneOfSchemas(Array[Schema])
  NotSchema(Schema)

  // Reference
  Ref(String)

  // Conditional
  If(Schema, Schema?, Schema?) // if, then, else

  // Generic schema with multiple types
  Multiple(Array[SchemaType])

  // Any type allowed
  Any
} derive(Show)

///|
pub struct StringConstraints {
  min_length : Int?
  max_length : Int?
  pattern : String?
  format : String?
  content_encoding : String?
  content_media_type : String?
} derive(Show)

///|
pub struct NumberConstraints {
  minimum : Double?
  maximum : Double?
  exclusive_minimum : Double?
  exclusive_maximum : Double?
  multiple_of : Double?
} derive(Show)

///|
pub struct ArrayConstraints {
  items : Schema?
  prefix_items : Array[Schema]?
  contains : Schema?
  min_contains : Int?
  max_contains : Int?
  min_items : Int?
  max_items : Int?
  unique_items : Bool?
} derive(Show)

///|
pub struct ObjectConstraints {
  properties : Map[String, Schema]?
  required : Array[String]?
  additional_properties : Schema?
  pattern_properties : Map[String, Schema]?
  property_names : Schema?
  dependent_schemas : Map[String, Schema]?
  dependent_required : Map[String, Array[String]]?
  min_properties : Int?
  max_properties : Int?
} derive(Show)

// Helper constructors

///|
pub fn Schema::string() -> Schema {
  String(StringConstraints::{
    min_length: None,
    max_length: None,
    pattern: None,
    format: None,
    content_encoding: None,
    content_media_type: None,
  })
}

///|
pub fn Schema::string_with_constraints(
  min_length : Int?,
  max_length : Int?,
  pattern : String?,
  format : String?,
) -> Schema {
  String(StringConstraints::{
    min_length,
    max_length,
    pattern,
    format,
    content_encoding: None,
    content_media_type: None,
  })
}

///|
pub fn Schema::number() -> Schema {
  Number(NumberConstraints::{
    minimum: None,
    maximum: None,
    exclusive_minimum: None,
    exclusive_maximum: None,
    multiple_of: None,
  })
}

///|
pub fn Schema::number_with_constraints(
  minimum : Double?,
  maximum : Double?,
  exclusive_minimum : Double?,
  exclusive_maximum : Double?,
  multiple_of : Double?,
) -> Schema {
  Number(NumberConstraints::{
    minimum,
    maximum,
    exclusive_minimum,
    exclusive_maximum,
    multiple_of,
  })
}

///|
pub fn Schema::integer() -> Schema {
  Integer(NumberConstraints::{
    minimum: None,
    maximum: None,
    exclusive_minimum: None,
    exclusive_maximum: None,
    multiple_of: None,
  })
}

///|
pub fn Schema::array(items : Schema?) -> Schema {
  Array(ArrayConstraints::{
    items,
    prefix_items: None,
    contains: None,
    min_contains: None,
    max_contains: None,
    min_items: None,
    max_items: None,
    unique_items: None,
  })
}

///|
pub fn Schema::array_with_constraints(
  items : Schema?,
  min_items : Int?,
  max_items : Int?,
  unique_items : Bool?,
) -> Schema {
  Array(ArrayConstraints::{
    items,
    prefix_items: None,
    contains: None,
    min_contains: None,
    max_contains: None,
    min_items,
    max_items,
    unique_items,
  })
}

///|
pub fn Schema::object(
  properties : Map[String, Schema]?,
  required : Array[String]?,
) -> Schema {
  Object(ObjectConstraints::{
    properties,
    required,
    additional_properties: None,
    pattern_properties: None,
    property_names: None,
    dependent_schemas: None,
    dependent_required: None,
    min_properties: None,
    max_properties: None,
  })
}

///|
pub fn Schema::enum_values(values : Array[Json]) -> Schema {
  EnumValues(values)
}

///|
pub fn Schema::any_of(schemas : Array[Schema]) -> Schema {
  AnyOfSchemas(schemas)
}

///|
pub fn Schema::all_of(schemas : Array[Schema]) -> Schema {
  AllOfSchemas(schemas)
}

///|
pub fn Schema::one_of(schemas : Array[Schema]) -> Schema {
  OneOfSchemas(schemas)
}

///|
pub fn Schema::not(schema : Schema) -> Schema {
  NotSchema(schema)
}

///|
pub fn Schema::null() -> Schema {
  Null
}

///|
pub fn Schema::boolean() -> Schema {
  Boolean
}

///|
pub fn Schema::const_value(value : Json) -> Schema {
  ConstValue(value)
}

///|
pub fn Schema::reference(ref_path : String) -> Schema {
  Ref(ref_path)
}

///|
pub fn Schema::if_then_else(
  if_schema : Schema,
  then_schema : Schema?,
  else_schema : Schema?,
) -> Schema {
  If(if_schema, then_schema, else_schema)
}

///|
pub fn Schema::multiple(types : Array[SchemaType]) -> Schema {
  Multiple(types)
}

///|
pub fn Schema::any() -> Schema {
  Any
}

// Parse JSON Schema from JSON object

///|
pub fn Schema::from_json(json : Json) -> Schema {
  match json {
    @json.Object(obj) => parse_schema_object(obj)
    @json.True => Schema::any() // true schema allows any value
    @json.False => Schema::not(Schema::any()) // false schema rejects all values
    _ => Schema::any() // Invalid schema defaults to any
  }
}

///|
fn parse_schema_object(obj : Map[String, Json]) -> Schema {
  // Check for type field
  match obj.get("type") {
    Some(@json.String(type_str)) =>
      match type_str {
        "null" => Schema::null()
        "boolean" => Schema::boolean()
        "string" => parse_string_schema(obj)
        "number" => parse_number_schema(obj)
        "integer" => parse_integer_schema(obj)
        "array" => parse_array_schema(obj)
        "object" => parse_object_schema(obj)
        _ => Schema::any()
      }
    Some(@json.Array(types)) => {
      // Multiple types
      let schema_types : Array[SchemaType] = []
      for i = 0; i < types.length(); i = i + 1 {
        match types[i] {
          @json.String("null") => schema_types.push(Null)
          @json.String("boolean") => schema_types.push(Boolean)
          @json.String("string") => schema_types.push(String)
          @json.String("number") => schema_types.push(Number)
          @json.String("integer") => schema_types.push(Integer)
          @json.String("array") => schema_types.push(Array)
          @json.String("object") => schema_types.push(Object)
          _ => ()
        }
      }
      if schema_types.length() > 0 {
        Schema::multiple(schema_types)
      } else {
        Schema::any()
      }
    }
    None =>
      // Check for composition keywords
      match obj.get("anyOf") {
        Some(@json.Array(schemas)) => {
          let parsed_schemas : Array[Schema] = []
          for i = 0; i < schemas.length(); i = i + 1 {
            parsed_schemas.push(Schema::from_json(schemas[i]))
          }
          Schema::any_of(parsed_schemas)
        }
        _ =>
          match obj.get("allOf") {
            Some(@json.Array(schemas)) => {
              let parsed_schemas : Array[Schema] = []
              for i = 0; i < schemas.length(); i = i + 1 {
                parsed_schemas.push(Schema::from_json(schemas[i]))
              }
              Schema::all_of(parsed_schemas)
            }
            _ =>
              match obj.get("oneOf") {
                Some(@json.Array(schemas)) => {
                  let parsed_schemas : Array[Schema] = []
                  for i = 0; i < schemas.length(); i = i + 1 {
                    parsed_schemas.push(Schema::from_json(schemas[i]))
                  }
                  Schema::one_of(parsed_schemas)
                }
                _ =>
                  match obj.get("not") {
                    Some(schema) => Schema::not(Schema::from_json(schema))
                    _ =>
                      match obj.get("enum") {
                        Some(@json.Array(values)) => Schema::enum_values(values)
                        _ =>
                          match obj.get("const") {
                            Some(value) => Schema::const_value(value)
                            _ => Schema::any()
                          }
                      }
                  }
              }
          }
      }
    _ => Schema::any()
  }
}

///|
fn parse_string_schema(obj : Map[String, Json]) -> Schema {
  let min_length = match obj.get("minLength") {
    Some(@json.Number(n, ..)) => Some(n.to_int())
    _ => None
  }
  let max_length = match obj.get("maxLength") {
    Some(@json.Number(n, ..)) => Some(n.to_int())
    _ => None
  }
  let pattern = match obj.get("pattern") {
    Some(@json.String(p)) => Some(p)
    _ => None
  }
  let format = match obj.get("format") {
    Some(@json.String(f)) => Some(f)
    _ => None
  }
  Schema::string_with_constraints(min_length, max_length, pattern, format)
}

///|
fn parse_number_schema(obj : Map[String, Json]) -> Schema {
  let minimum = match obj.get("minimum") {
    Some(@json.Number(n, ..)) => Some(n)
    _ => None
  }
  let maximum = match obj.get("maximum") {
    Some(@json.Number(n, ..)) => Some(n)
    _ => None
  }
  let exclusive_minimum = match obj.get("exclusiveMinimum") {
    Some(@json.Number(n, ..)) => Some(n)
    _ => None
  }
  let exclusive_maximum = match obj.get("exclusiveMaximum") {
    Some(@json.Number(n, ..)) => Some(n)
    _ => None
  }
  let multiple_of = match obj.get("multipleOf") {
    Some(@json.Number(n, ..)) => Some(n)
    _ => None
  }
  Schema::number_with_constraints(
    minimum, maximum, exclusive_minimum, exclusive_maximum, multiple_of,
  )
}

///|
fn parse_integer_schema(obj : Map[String, Json]) -> Schema {
  let minimum = match obj.get("minimum") {
    Some(@json.Number(n, ..)) => Some(n)
    _ => None
  }
  let maximum = match obj.get("maximum") {
    Some(@json.Number(n, ..)) => Some(n)
    _ => None
  }
  let exclusive_minimum = match obj.get("exclusiveMinimum") {
    Some(@json.Number(n, ..)) => Some(n)
    _ => None
  }
  let exclusive_maximum = match obj.get("exclusiveMaximum") {
    Some(@json.Number(n, ..)) => Some(n)
    _ => None
  }
  let multiple_of = match obj.get("multipleOf") {
    Some(@json.Number(n, ..)) => Some(n)
    _ => None
  }
  Integer(NumberConstraints::{
    minimum,
    maximum,
    exclusive_minimum,
    exclusive_maximum,
    multiple_of,
  })
}

///|
fn parse_array_schema(obj : Map[String, Json]) -> Schema {
  let items = match obj.get("items") {
    Some(item_schema) => Some(Schema::from_json(item_schema))
    None => None
  }
  let min_items = match obj.get("minItems") {
    Some(@json.Number(n, ..)) => Some(n.to_int())
    _ => None
  }
  let max_items = match obj.get("maxItems") {
    Some(@json.Number(n, ..)) => Some(n.to_int())
    _ => None
  }
  let unique_items = match obj.get("uniqueItems") {
    Some(@json.True) => Some(true)
    Some(@json.False) => Some(false)
    _ => None
  }
  Schema::array_with_constraints(items, min_items, max_items, unique_items)
}

///|
fn parse_object_schema(obj : Map[String, Json]) -> Schema {
  let properties = match obj.get("properties") {
    Some(@json.Object(props_obj)) => {
      let props_map : Map[String, Schema] = Map::new()
      props_obj.each(fn(key, value) {
        props_map.set(key, Schema::from_json(value))
      })
      Some(props_map)
    }
    _ => None
  }
  let required = match obj.get("required") {
    Some(@json.Array(req_array)) => {
      let req_props : Array[String] = []
      for i = 0; i < req_array.length(); i = i + 1 {
        match req_array[i] {
          @json.String(prop) => req_props.push(prop)
          _ => ()
        }
      }
      Some(req_props)
    }
    _ => None
  }
  Schema::object(properties, required)
}

///|
pub struct ValidationError {
  path : String
  message : String
  schema_path : String
} derive(Show)

///|
pub fn ValidationError::new(
  path : String,
  message : String,
  schema_path : String,
) -> ValidationError {
  ValidationError::{ path, message, schema_path }
}

///|
pub enum ValidationResult {
  Ok
  Err(Array[ValidationError])
} derive(Show)
