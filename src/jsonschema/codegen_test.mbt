// Tests for JSON Schema to MoonBit code generator

test "generate struct from object schema" {
  let props = Map::of([
    ("name", Schema::string()),
    ("age", Schema::integer()),
    ("email", Schema::string())
  ])
  
  let schema = Schema::object(
    Some(props),
    Some(["name", "age"])  // name and age are required
  )
  
  let options = CodegenOptions::with_derives(["Show", "ToJson"])
  let code = generate_moonbit_code(schema, "User", options)
  
  // Check that generated code contains expected elements
  assert_true(code.contains("pub struct User"))
  assert_true(code.contains("name : String"))
  assert_true(code.contains("age : Int"))
  assert_true(code.contains("email : String?"))  // optional
  assert_true(code.contains("derive(Show, ToJson)"))
  assert_true(code.contains("pub fn User::new"))
}

test "generate enum from enum schema" {
  let enum_values : Array[Json] = []
  enum_values.push(Json::string("red"))
  enum_values.push(Json::string("green"))
  enum_values.push(Json::string("blue"))
  
  let schema = Schema::enum_values(enum_values)
  let options = CodegenOptions::with_derives(["Show", "Eq"])
  let code = generate_moonbit_code(schema, "Color", options)
  
  // Check enum generation
  assert_true(code.contains("pub enum Color"))
  assert_true(code.contains("Red"))
  assert_true(code.contains("Green"))
  assert_true(code.contains("Blue"))
  assert_true(code.contains("derive(Show, Eq)"))
  
  // Check conversion functions
  assert_true(code.contains("fn Color::from_string"))
  assert_true(code.contains("fn to_string(self : Color)"))
}

test "generate array type alias" {
  let item_schema = Schema::string()
  let schema = Schema::array(Some(item_schema))
  let options = CodegenOptions::default()
  let code = generate_moonbit_code(schema, "StringList", options)
  
  assert_true(code.contains("pub type StringList = Array[String]"))
}

test "generate nested object schema" {
  let address_props = Map::of([
    ("street", Schema::string()),
    ("city", Schema::string()),
    ("zipCode", Schema::string())
  ])
  
  let address_schema = Schema::object(
    Some(address_props),
    Some(["street", "city"])
  )
  
  let person_props = Map::of([
    ("name", Schema::string()),
    ("age", Schema::integer()),
    ("address", address_schema)
  ])
  
  let person_schema = Schema::object(
    Some(person_props),
    Some(["name"])
  )
  
  let options = CodegenOptions::with_derives(["Show"])
  let code = generate_moonbit_code(person_schema, "Person", options)
  
  // Check structure
  assert_true(code.contains("pub struct Person"))
  assert_true(code.contains("name : String"))
  assert_true(code.contains("age : Int?"))
  assert_true(code.contains("address : Map[String, Json]?"))
}

test "generate union type from anyOf" {
  let schemas : Array[Schema] = []
  schemas.push(Schema::string())
  schemas.push(Schema::number())
  
  let schema = Schema::any_of(schemas)
  let options = CodegenOptions::default()
  let code = generate_moonbit_code(schema, "StringOrNumber", options)
  
  assert_true(code.contains("pub enum StringOrNumber"))
  assert_true(code.contains("Variant1(String)"))
  assert_true(code.contains("Variant2(Double)"))
}

test "generate code without public visibility" {
  let props = Map::of([
    ("id", Schema::integer())
  ])
  
  let schema = Schema::object(Some(props), Some(["id"]))
  let options = CodegenOptions::{
    derives: [],
    use_pub: false,
    indent: "  "
  }
  let code = generate_moonbit_code(schema, "Private", options)
  
  // Should not contain "pub"
  assert_false(code.contains("pub struct"))
  assert_false(code.contains("pub fn"))
  assert_true(code.contains("struct Private"))
  assert_true(code.contains("fn Private::new"))
}

test "convert identifiers to moonbit style" {
  // Test various naming conversions
  assert_true(to_moonbit_identifier("user-name") == "user_name")
  assert_true(to_moonbit_identifier("firstName") == "first_name")
  assert_true(to_moonbit_identifier("UserID") == "user_i_d")
  
  assert_true(to_pascal_case("red") == "Red")
  assert_true(to_pascal_case("dark-blue") == "DarkBlue")
  assert_true(to_pascal_case("my_enum_value") == "MyEnumValue")
}