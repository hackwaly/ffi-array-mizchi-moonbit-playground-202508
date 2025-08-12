// 関数型DSLのテスト

test "functional_service_definition" {
  let service = define_service("TestService", "1.0.0", fn(s) {
    s
      .typedef("Product", object([
        ("id", string()),
        ("name", string()),
        ("price", number())
      ]))
      .function("getProduct", 
        func([("id", string())], ref("Product"))
      )
  })
  
  assert_eq(service.name, "TestService")
  assert_eq(service.version, "1.0.0")
  assert_true(service.functions.contains("getProduct"))
  assert_true(service.types.contains("Product"))
}

test "function_spec_creation" {
  // 基本的な関数
  let simple = func(
    [("name", string())],
    string()
  )
  assert_eq(simple.params.length(), 1)
  assert_eq(simple.returns, string())
  assert_true(simple.throws.is_none())
  
  // 例外付き関数
  let with_error = func_throws(
    [("id", string())],
    string(),
    object([("error", string())])
  )
  assert_true(with_error.throws.is_some())
  
  // オプショナルパラメータ
  let with_optional = func_with_optional(
    [
      ("required", string(), true),
      ("optional", number(), false)
    ],
    boolean()
  )
  assert_eq(with_optional.params.length(), 2)
}

test "type_helpers" {
  // 基本型
  assert_eq(string(), @jsonschema/types.Schema::String({
    min_length: None,
    max_length: None,
    pattern: None,
    format: None,
    content_encoding: None,
    content_media_type: None
  }))
  
  assert_eq(boolean(), @jsonschema/types.Schema::Boolean)
  
  // 複合型
  let arr = array(string())
  match arr {
    @jsonschema/types.Schema::Array(constraints) => {
      assert_true(constraints.items.is_some())
    }
    _ => assert_true(false)
  }
  
  // オブジェクト型
  let obj = object([
    ("field1", string()),
    ("field2", number())
  ])
  match obj {
    @jsonschema/types.Schema::Object(constraints) => {
      match constraints.properties {
        Some(props) => {
          assert_true(props.contains("field1"))
          assert_true(props.contains("field2"))
        }
        None => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

test "optional_and_union_types" {
  // オプショナル型
  let opt = optional(string())
  match opt {
    @jsonschema/types.Schema::AnyOfSchemas(schemas) => {
      assert_eq(schemas.length(), 2)
    }
    _ => assert_true(false)
  }
  
  // ユニオン型
  let uni = union([string(), number(), boolean()])
  match uni {
    @jsonschema/types.Schema::AnyOfSchemas(schemas) => {
      assert_eq(schemas.length(), 3)
    }
    _ => assert_true(false)
  }
}

test "ref_type" {
  let user_ref = ref("User")
  match user_ref {
    @jsonschema/types.Schema::Ref(name) => {
      assert_eq(name, "#/definitions/User")
    }
    _ => assert_true(false)
  }
}

test "function_with_description" {
  let spec = func(
    [("input", string())],
    string()
  ).with_description("Process input string")
  
  match spec.description {
    Some(desc) => assert_eq(desc, "Process input string")
    None => assert_true(false)
  }
}

test "complete_service_example" {
  let service = create_example_service()
  
  assert_eq(service.name, "UserService")
  assert_eq(service.version, "1.0.0")
  
  // 型定義の確認
  assert_true(service.types.contains("User"))
  assert_true(service.types.contains("Error"))
  
  // 関数定義の確認
  assert_true(service.functions.contains("getUser"))
  assert_true(service.functions.contains("createUser"))
  assert_true(service.functions.contains("updateUser"))
  assert_true(service.functions.contains("listUsers"))
  assert_true(service.functions.contains("searchUsers"))
  
  // getUser関数の詳細確認
  match service.functions.get("getUser") {
    Some(func) => {
      assert_eq(func.name, "getUser")
      assert_true(func.description.is_some())
    }
    None => assert_true(false)
  }
}

test "function_composition" {
  // string -> number
  let f1 = func(
    [("text", string())],
    number()
  )
  
  // number -> boolean
  let f2 = func(
    [("value", number())],
    boolean()
  )
  
  // 関数合成: string -> boolean
  match compose_specs(f1, f2) {
    Some(composed) => {
      assert_eq(composed.params.length(), 1)
      let (name, param_type, _) = composed.params[0]
      assert_eq(param_type, string())
      assert_eq(composed.returns, boolean())
    }
    None => assert_true(false)
  }
}

test "pipeline_composition" {
  let pipeline = pipe([
    func([("input", string())], number()),
    func([("n", number())], boolean()),
    func([("b", boolean())], string())
  ])
  
  match pipeline {
    Some(spec) => {
      // 入力は最初の関数のパラメータ
      assert_eq(spec.params.length(), 1)
      let (_, param_type, _) = spec.params[0]
      assert_eq(param_type, string())
      
      // 出力は最後の関数の戻り値
      assert_eq(spec.returns, string())
    }
    None => assert_true(false)
  }
}

test "nested_service_definition" {
  let service = define_service("ComplexService", "2.0.0", fn(s) {
    s
      // 基本型定義
      .typedef("ID", string())
      .typedef("Timestamp", number())
      
      // 複合型定義
      .typedef("Address", object([
        ("street", string()),
        ("city", string()),
        ("zipCode", string())
      ]))
      
      .typedef("Person", object([
        ("id", ref("ID")),
        ("name", string()),
        ("address", ref("Address")),
        ("createdAt", ref("Timestamp"))
      ]))
      
      // CRUD操作
      .function("create",
        func_throws(
          [("data", ref("Person"))],
          ref("Person"),
          ref("Error")
        )
      )
      .function("read",
        func(
          [("id", ref("ID"))],
          optional(ref("Person"))
        )
      )
      .function("update",
        func_throws(
          [("id", ref("ID")), ("data", ref("Person"))],
          ref("Person"),
          ref("Error")
        )
      )
      .function("delete",
        func_throws(
          [("id", ref("ID"))],
          boolean(),
          ref("Error")
        )
      )
  })
  
  assert_eq(service.name, "ComplexService")
  assert_eq(service.types.length(), 4)
  assert_eq(service.functions.length(), 4)
}