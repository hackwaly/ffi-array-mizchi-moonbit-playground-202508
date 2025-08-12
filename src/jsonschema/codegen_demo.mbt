// Demo: JSON Schema to MoonBit code generation

fn demo_generate_user_struct() -> Unit {
  // Create a JSON Schema for a User type
  let user_schema = Schema::object(
    Some(Map::of([
      ("id", Schema::integer()),
      ("name", Schema::string()),
      ("email", Schema::string_with_constraints(None, None, None, Some("email"))),
      ("age", Schema::integer()),
      ("is_active", Schema::boolean()),
      ("tags", Schema::array(Some(Schema::string()))),
      ("address", Schema::object(
        Some(Map::of([
          ("street", Schema::string()),
          ("city", Schema::string()),
          ("zip_code", Schema::string())
        ])),
        Some(["street", "city"])
      ))
    ])),
    Some(["id", "name", "email"])  // Required fields
  )
  
  // Generate MoonBit code with derives
  let options = CodegenOptions::with_derives(["Show", "Eq", "ToJson"])
  let generated_code = generate_moonbit_code(user_schema, "User", options)
  
  println("Generated User struct:")
  println(generated_code)
  println("\n" + "=".repeat(50) + "\n")
}

fn demo_generate_status_enum() -> Unit {
  // Create an enum schema for status values
  let status_values : Array[Json] = []
  status_values.push(Json::string("pending"))
  status_values.push(Json::string("in-progress"))
  status_values.push(Json::string("completed"))
  status_values.push(Json::string("cancelled"))
  
  let status_schema = Schema::enum_values(status_values)
  
  // Generate MoonBit enum
  let options = CodegenOptions::with_derives(["Show", "Eq"])
  let generated_code = generate_moonbit_code(status_schema, "Status", options)
  
  println("Generated Status enum:")
  println(generated_code)
  println("\n" + "=".repeat(50) + "\n")
}

fn demo_generate_from_json_schema() -> Unit {
  // Parse a JSON Schema from JSON
  let schema_json = Json::object(Map::of([
    ("type", Json::string("object")),
    ("properties", Json::object(Map::of([
      ("product_id", Json::object(Map::of([
        ("type", Json::string("string")),
        ("pattern", Json::string("^[A-Z]{3}-[0-9]{4}$"))
      ]))),
      ("product_name", Json::object(Map::of([
        ("type", Json::string("string")),
        ("minLength", Json::number(1.0)),
        ("maxLength", Json::number(100.0))
      ]))),
      ("price", Json::object(Map::of([
        ("type", Json::string("number")),
        ("minimum", Json::number(0.0))
      ]))),
      ("in_stock", Json::object(Map::of([
        ("type", Json::string("boolean"))
      ]))),
      ("categories", Json::object(Map::of([
        ("type", Json::string("array")),
        ("items", Json::object(Map::of([
          ("type", Json::string("string"))
        ])))
      ])))
    ]))),
    ("required", Json::array([
      Json::string("product_id"),
      Json::string("product_name"),
      Json::string("price")
    ]))
  ]))
  
  let schema = Schema::from_json(schema_json)
  let options = CodegenOptions::with_derives(["Show", "ToJson"])
  let generated_code = generate_moonbit_code(schema, "Product", options)
  
  println("Generated Product struct from JSON Schema:")
  println(generated_code)
  println("\n" + "=".repeat(50) + "\n")
}

fn demo_generate_union_type() -> Unit {
  // Create a union type (anyOf) schema
  let response_schema = Schema::any_of([
    Schema::object(
      Some(Map::of([
        ("success", Schema::boolean()),
        ("data", Schema::any())
      ])),
      Some(["success", "data"])
    ),
    Schema::object(
      Some(Map::of([
        ("error", Schema::string()),
        ("code", Schema::integer())
      ])),
      Some(["error", "code"])
    )
  ])
  
  let options = CodegenOptions::default()
  let generated_code = generate_moonbit_code(response_schema, "ApiResponse", options)
  
  println("Generated ApiResponse union type:")
  println(generated_code)
}

test "codegen_demo" {
  println("JSON Schema to MoonBit Code Generator Demo")
  println("==================================================")
  println("")
  
  demo_generate_user_struct()
  demo_generate_status_enum()
  demo_generate_from_json_schema()
  demo_generate_union_type()
  
  println("\nDemo completed!")
}

