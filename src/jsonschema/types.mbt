// JSON Schema types and definitions
// Using built-in @json.JsonValue instead of custom JsonValue type

pub enum SchemaType {
  Null
  Boolean
  Number
  Integer
  String
  Array
  Object
} derive(Show)

pub struct Schema {
  // JSON Schema 2020-12 meta-schema properties
  schema_uri : Option[String] // $schema
  id : Option[String] // $id
  anchor : Option[String] // $anchor
  ref_ : Option[String] // $ref
  defs : Option[Map[String, Schema]] // $defs
  vocabulary : Option[Map[String, Bool]] // $vocabulary
  comment : Option[String] // $comment
  
  // Type constraints
  type_ : Option[SchemaType]
  types : Option[Array[SchemaType]]
  
  // Common validations
  enum_ : Option[Array[Json]]
  const_ : Option[Json]
  
  // Numeric validations
  minimum : Option[Double]
  maximum : Option[Double]
  exclusive_minimum : Option[Double]
  exclusive_maximum : Option[Double]
  multiple_of : Option[Double]
  
  // String validations
  min_length : Option[Int]
  max_length : Option[Int]
  pattern : Option[String]
  format : Option[String]
  content_encoding : Option[String]
  content_media_type : Option[String]
  content_schema : Option[Schema]
  
  // Array validations
  items : Option[Schema]
  prefix_items : Option[Array[Schema]] // New in 2020-12
  contains : Option[Schema]
  min_contains : Option[Int] // New in 2019-09
  max_contains : Option[Int] // New in 2019-09
  min_items : Option[Int]
  max_items : Option[Int]
  unique_items : Option[Bool]
  
  // Object validations
  properties : Option[Map[String, Schema]]
  required : Option[Array[String]]
  additional_properties : Option[Schema]
  pattern_properties : Option[Map[String, Schema]]
  property_names : Option[Schema]
  dependent_schemas : Option[Map[String, Schema]] // Replaces dependencies
  dependent_required : Option[Map[String, Array[String]]] // Replaces dependencies
  min_properties : Option[Int]
  max_properties : Option[Int]
  
  // Logical operations
  all_of : Option[Array[Schema]]
  any_of : Option[Array[Schema]]
  one_of : Option[Array[Schema]]
  not_ : Option[Schema]
  
  // Conditional
  if_ : Option[Schema]
  then_ : Option[Schema]
  else_ : Option[Schema]
  
  // Metadata
  title : Option[String]
  description : Option[String]
  default : Option[Json]
  examples : Option[Array[Json]]
  deprecated : Option[Bool] // New in 2019-09
  read_only : Option[Bool]
  write_only : Option[Bool]
}

pub fn Schema::new() -> Schema {
  Schema::{
    // Meta-schema properties
    schema_uri: None,
    id: None,
    anchor: None,
    ref_: None,
    defs: None,
    vocabulary: None,
    comment: None,
    // Type constraints
    type_: None,
    types: None,
    enum_: None,
    const_: None,
    minimum: None,
    maximum: None,
    exclusive_minimum: None,
    exclusive_maximum: None,
    multiple_of: None,
    min_length: None,
    max_length: None,
    pattern: None,
    format: None,
    content_encoding: None,
    content_media_type: None,
    content_schema: None,
    items: None,
    prefix_items: None,
    contains: None,
    min_contains: None,
    max_contains: None,
    min_items: None,
    max_items: None,
    unique_items: None,
    properties: None,
    required: None,
    additional_properties: None,
    pattern_properties: None,
    property_names: None,
    dependent_schemas: None,
    dependent_required: None,
    min_properties: None,
    max_properties: None,
    all_of: None,
    any_of: None,
    one_of: None,
    not_: None,
    if_: None,
    then_: None,
    else_: None,
    title: None,
    description: None,
    default: None,
    examples: None,
    deprecated: None,
    read_only: None,
    write_only: None
  }
}

pub struct ValidationError {
  path : String
  message : String
  schema_path : String
}

pub fn ValidationError::new(path : String, message : String, schema_path : String) -> ValidationError {
  ValidationError::{path, message, schema_path}
}

pub enum ValidationResult {
  Ok
  Err(Array[ValidationError])
}