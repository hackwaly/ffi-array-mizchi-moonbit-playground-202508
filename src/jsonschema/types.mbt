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
  mut schema_uri : Option[String] // $schema
  mut id : Option[String] // $id
  mut anchor : Option[String] // $anchor
  mut ref_ : Option[String] // $ref
  mut defs : Option[Map[String, Schema]] // $defs
  mut vocabulary : Option[Map[String, Bool]] // $vocabulary
  mut comment : Option[String] // $comment
  
  // Type constraints
  mut type_ : Option[SchemaType]
  mut types : Option[Array[SchemaType]]
  
  // Common validations
  mut enum_ : Option[Array[Json]]
  mut const_ : Option[Json]
  
  // Numeric validations
  mut minimum : Option[Double]
  mut maximum : Option[Double]
  mut exclusive_minimum : Option[Double]
  mut exclusive_maximum : Option[Double]
  mut multiple_of : Option[Double]
  
  // String validations
  mut min_length : Option[Int]
  mut max_length : Option[Int]
  mut pattern : Option[String]
  mut format : Option[String]
  mut content_encoding : Option[String]
  mut content_media_type : Option[String]
  mut content_schema : Option[Schema]
  
  // Array validations
  mut items : Option[Schema]
  mut prefix_items : Option[Array[Schema]] // New in 2020-12
  mut contains : Option[Schema]
  mut min_contains : Option[Int] // New in 2019-09
  mut max_contains : Option[Int] // New in 2019-09
  mut min_items : Option[Int]
  mut max_items : Option[Int]
  mut unique_items : Option[Bool]
  
  // Object validations
  mut properties : Option[Map[String, Schema]]
  mut required : Option[Array[String]]
  mut additional_properties : Option[Schema]
  mut pattern_properties : Option[Map[String, Schema]]
  mut property_names : Option[Schema]
  mut dependent_schemas : Option[Map[String, Schema]] // Replaces dependencies
  mut dependent_required : Option[Map[String, Array[String]]] // Replaces dependencies
  mut min_properties : Option[Int]
  mut max_properties : Option[Int]
  
  // Logical operations
  mut all_of : Option[Array[Schema]]
  mut any_of : Option[Array[Schema]]
  mut one_of : Option[Array[Schema]]
  mut not_ : Option[Schema]
  
  // Conditional
  mut if_ : Option[Schema]
  mut then_ : Option[Schema]
  mut else_ : Option[Schema]
  
  // Metadata
  mut title : Option[String]
  mut description : Option[String]
  mut default : Option[Json]
  mut examples : Option[Array[Json]]
  mut deprecated : Option[Bool] // New in 2019-09
  mut read_only : Option[Bool]
  mut write_only : Option[Bool]
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