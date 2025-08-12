// JSON Schema拡張のテスト

test "function_schema_json_generation" {
  // シンプルな関数: (string) -> number
  let params = [
    @json.JsonValue::Object({
      let obj = Map::new()
      obj["name"] = @json.JsonValue::String("input")
      obj["type"] = standard_string()
      obj["optional"] = @json.JsonValue::False
      obj
    })
  ]
  
  let func_json = function_schema_json(
    params,
    standard_number(),
    None,
    None,
    None
  )
  
  match func_json {
    @json.JsonValue::Object(obj) => {
      // $functionマーカーの確認
      match obj.get("$function") {
        Some(@json.JsonValue::True) => assert_true(true)
        _ => assert_true(false)
      }
      
      // パラメータの確認
      assert_true(obj.contains("$parameters"))
      
      // 戻り値の確認
      assert_true(obj.contains("$returns"))
    }
    _ => assert_true(false)
  }
}

test "generic_function_json" {
  // ジェネリック関数: <T>(T) -> T
  let params = [
    @json.JsonValue::Object({
      let obj = Map::new()
      obj["name"] = @json.JsonValue::String("value")
      obj["type"] = type_param_json("T", None)
      obj["optional"] = @json.JsonValue::False
      obj
    })
  ]
  
  let func_json = function_schema_json(
    params,
    type_param_json("T", None),
    None,
    Some(["T"]),
    None
  )
  
  match func_json {
    @json.JsonValue::Object(obj) => {
      // ジェネリクスの確認
      match obj.get("$generic") {
        Some(@json.JsonValue::Array(generics)) => {
          assert_eq(generics.length(), 1)
          match generics[0] {
            @json.JsonValue::String(name) => assert_eq(name, "T")
            _ => assert_true(false)
          }
        }
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

test "async_schema_json_generation" {
  // Promise<string>
  let promise_json = async_schema_json("Promise", standard_string())
  
  match promise_json {
    @json.JsonValue::Object(obj) => {
      match obj.get("$async") {
        Some(@json.JsonValue::String(async_type)) => {
          assert_eq(async_type, "Promise")
        }
        _ => assert_true(false)
      }
      
      assert_true(obj.contains("$resolves"))
    }
    _ => assert_true(false)
  }
}

test "result_schema_json_generation" {
  // Result<string, Error>
  let result_json = result_schema_json(
    standard_string(),
    standard_object({
      let props = Map::new()
      props["message"] = standard_string()
      props
    }, Some(["message"]))
  )
  
  match result_json {
    @json.JsonValue::Object(obj) => {
      match obj.get("$result") {
        Some(@json.JsonValue::True) => assert_true(true)
        _ => assert_true(false)
      }
      
      assert_true(obj.contains("$ok"))
      assert_true(obj.contains("$error"))
    }
    _ => assert_true(false)
  }
}

test "dsl_builder_basic_types" {
  // 基本型のテスト
  let string_schema = schema().string().build()
  match string_schema {
    @json.JsonValue::Object(obj) => {
      match obj.get("type") {
        Some(@json.JsonValue::String(t)) => assert_eq(t, "string")
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
  
  let number_schema = schema().number().build()
  match number_schema {
    @json.JsonValue::Object(obj) => {
      match obj.get("type") {
        Some(@json.JsonValue::String(t)) => assert_eq(t, "number")
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

test "dsl_builder_function" {
  // (string, number?) -> boolean
  let func = schema().function(
    [
      ("name", schema().string(), false),
      ("age", schema().number(), true)
    ],
    schema().boolean()
  ).build()
  
  match func {
    @json.JsonValue::Object(obj) => {
      // 関数マーカー
      match obj.get("$function") {
        Some(@json.JsonValue::True) => assert_true(true)
        _ => assert_true(false)
      }
      
      // パラメータ配列
      match obj.get("$parameters") {
        Some(@json.JsonValue::Array(params)) => {
          assert_eq(params.length(), 2)
        }
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

test "dsl_builder_promise" {
  // Promise<string>
  let promise = schema().promise(schema().string()).build()
  
  match promise {
    @json.JsonValue::Object(obj) => {
      match obj.get("$async") {
        Some(@json.JsonValue::String(async_type)) => {
          assert_eq(async_type, "Promise")
        }
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

test "dsl_builder_result" {
  // Result<User, Error>
  let result = schema().result(
    schema().ref("#/definitions/User"),
    schema().ref("#/definitions/Error")
  ).build()
  
  match result {
    @json.JsonValue::Object(obj) => {
      match obj.get("$result") {
        Some(@json.JsonValue::True) => assert_true(true)
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

test "dsl_builder_generic_function" {
  // map<T, U>: (T -> U) -> Array<T> -> Array<U>
  let map_func = schema().generic_function(
    ["T", "U"],
    [
      ("mapper", schema().function(
        [("value", schema().type_param("T"), false)],
        schema().type_param("U")
      ), false),
      ("array", schema().array(schema().type_param("T")), false)
    ],
    schema().array(schema().type_param("U"))
  ).build()
  
  match map_func {
    @json.JsonValue::Object(obj) => {
      // ジェネリクスの確認
      match obj.get("$generic") {
        Some(@json.JsonValue::Array(generics)) => {
          assert_eq(generics.length(), 2)
        }
        _ => assert_true(false)
      }
      
      // パラメータの確認
      match obj.get("$parameters") {
        Some(@json.JsonValue::Array(params)) => {
          assert_eq(params.length(), 2)
        }
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

test "dsl_builder_effect" {
  // Effect<IO, string>
  let io_effect = schema().effect(
    "IO",
    schema().string(),
    ["read", "write", "network"]
  ).build()
  
  match io_effect {
    @json.JsonValue::Object(obj) => {
      match obj.get("$effect") {
        Some(@json.JsonValue::String(effect_name)) => {
          assert_eq(effect_name, "IO")
        }
        _ => assert_true(false)
      }
      
      match obj.get("$effects") {
        Some(@json.JsonValue::Array(effects)) => {
          assert_eq(effects.length(), 3)
        }
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

test "dsl_builder_complex_composition" {
  // compose<A, B, C>: ((B -> C), (A -> B)) -> (A -> C)
  let compose = schema().generic_function(
    ["A", "B", "C"],
    [
      ("f", schema().function(
        [("x", schema().type_param("B"), false)],
        schema().type_param("C")
      ), false),
      ("g", schema().function(
        [("x", schema().type_param("A"), false)],
        schema().type_param("B")
      ), false)
    ],
    schema().function(
      [("x", schema().type_param("A"), false)],
      schema().type_param("C")
    )
  ).build()
  
  match compose {
    @json.JsonValue::Object(obj) => {
      // ジェネリクスは3つ
      match obj.get("$generic") {
        Some(@json.JsonValue::Array(generics)) => {
          assert_eq(generics.length(), 3)
        }
        _ => assert_true(false)
      }
      
      // パラメータは2つの関数
      match obj.get("$parameters") {
        Some(@json.JsonValue::Array(params)) => {
          assert_eq(params.length(), 2)
        }
        _ => assert_true(false)
      }
      
      // 戻り値も関数
      match obj.get("$returns") {
        Some(@json.JsonValue::Object(ret_obj)) => {
          assert_true(ret_obj.contains("$function"))
        }
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}