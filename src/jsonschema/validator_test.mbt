// JSON Schema Validator tests

test "validate string type" {
  let schema = Schema::{
    ..Schema::new(),
    type_: Some(String)
  }
  
  let validator = Validator::new(schema)
  
  // Valid string
  let result1 = validator.validate(String("hello"))
  inspect!(result1, content="Ok")
  
  // Invalid - number instead of string
  let validator2 = Validator::new(schema)
  let result2 = validator2.validate(Number(42.0, ..))
  match result2 {
    Err(errors) => assert_true(errors.length() > 0)
    Ok => assert_false(true)
  }
}

test "validate number constraints" {
  let schema = Schema::{
    ..Schema::new(),
    type_: Some(Number),
    minimum: Some(0.0),
    maximum: Some(100.0)
  }
  
  let validator = Validator::new(schema)
  
  // Valid number
  let result1 = validator.validate(Number(50.0, ..))
  inspect!(result1, content="Ok")
  
  // Too small
  let validator2 = Validator::new(schema)
  let result2 = validator2.validate(Number(-10.0, ..))
  match result2 {
    Err(errors) => assert_true(errors.length() > 0)
    Ok => assert_false(true)
  }
  
  // Too large
  let validator3 = Validator::new(schema)
  let result3 = validator3.validate(Number(150.0, ..))
  match result3 {
    Err(errors) => assert_true(errors.length() > 0)
    Ok => assert_false(true)
  }
}

test "validate array constraints" {
  let schema = Schema::{
    ..Schema::new(),
    type_: Some(Array),
    min_items: Some(1),
    max_items: Some(3)
  }
  
  let validator = Validator::new(schema)
  
  // Valid array
  let arr = [String("a"), String("b")]
  let result1 = validator.validate(Array(arr))
  inspect!(result1, content="Ok")
  
  // Empty array (too small)
  let validator2 = Validator::new(schema)
  let result2 = validator2.validate(Array([]))
  match result2 {
    Err(errors) => assert_true(errors.length() > 0)
    Ok => assert_false(true)
  }
}

test "validate object with required properties" {
  let schema = Schema::{
    ..Schema::new(),
    type_: Some(Object),
    required: Some(["name", "age"]),
    properties: Some({
      let props = Map::new()
      let name_schema = Schema::{
        ..Schema::new(),
        type_: Some(String)
      }
      props.set("name", name_schema)
      
      let age_schema = Schema::{
        ..Schema::new(),
        type_: Some(Number)
      }
      props.set("age", age_schema)
      props
    })
  }
  
  let validator = Validator::new(schema)
  
  // Valid object
  let obj = Map::new()
  obj.set("name", String("John"))
  obj.set("age", Number(30.0, ..))
  let result1 = validator.validate(Object(obj))
  inspect!(result1, content="Ok")
  
  // Missing required property
  let validator2 = Validator::new(schema)
  let obj2 = Map::new()
  obj2.set("name", String("Jane"))
  let result2 = validator2.validate(Object(obj2))
  match result2 {
    Err(errors) => assert_true(errors.length() > 0)
    Ok => assert_false(true)
  }
}

test "validate enum values" {
  let schema = Schema::{
    ..Schema::new(),
    enum_: Some([String("red"), String("green"), String("blue")])
  }
  
  let validator = Validator::new(schema)
  
  // Valid enum value
  let result1 = validator.validate(String("red"))
  inspect!(result1, content="Ok")
  
  // Invalid enum value
  let validator2 = Validator::new(schema)
  let result2 = validator2.validate(String("yellow"))
  match result2 {
    Err(errors) => assert_true(errors.length() > 0)
    Ok => assert_false(true)
  }
}

test "validate anyOf schemas" {
  let string_schema = Schema::{
    ..Schema::new(),
    type_: Some(String)
  }
  
  let number_schema = Schema::{
    ..Schema::new(),
    type_: Some(Number)
  }
  
  let schema = Schema::{
    ..Schema::new(),
    any_of: Some([string_schema, number_schema])
  }
  
  let validator = Validator::new(schema)
  
  // Valid - string
  let result1 = validator.validate(String("hello"))
  inspect!(result1, content="Ok")
  
  // Valid - number
  let validator2 = Validator::new(schema)
  let result2 = validator2.validate(Number(42.0, ..))
  inspect!(result2, content="Ok")
  
  // Invalid - boolean
  let validator3 = Validator::new(schema)
  let result3 = validator3.validate(True)
  match result3 {
    Err(errors) => assert_true(errors.length() > 0)
    Ok => assert_false(true)
  }
}

test "parse simple schema from JSON" {
  let json_str = r#"{
    "type": "object",
    "properties": {
      "name": { "type": "string" },
      "age": { "type": "number", "minimum": 0 }
    },
    "required": ["name"]
  }"#
  
  match @json.parse(json_str) {
    Ok(json) => {
      match parse_schema(json) {
        Some(schema) => {
          match schema.type_ {
            Some(Object) => assert_true(true)
            _ => assert_false(true)
          }
        }
        None => assert_false(true)
      }
    }
    Err(_) => assert_false(true)
  }
}