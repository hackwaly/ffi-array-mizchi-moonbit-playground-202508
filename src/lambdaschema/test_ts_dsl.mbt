// TypeScript DSLのテスト

test "basic_types" {
  // string型
  let str = ts().string().build()
  match str {
    Json::Object(obj) => {
      match obj.get("type") {
        Some(Json::String(t)) => assert_eq(t, "string")
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
  
  // number型
  let num = ts().number().build()
  match num {
    Json::Object(obj) => {
      match obj.get("type") {
        Some(Json::String(t)) => assert_eq(t, "number")
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
  
  // boolean型
  let bool = ts().boolean().build()
  match bool {
    Json::Object(obj) => {
      match obj.get("type") {
        Some(Json::String(t)) => assert_eq(t, "boolean")
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

test "generic_types" {
  // Array<string>
  let array_string = ts().array(ts().string()).build()
  match array_string {
    Json::Object(obj) => {
      match obj.get("type") {
        Some(Json::String(t)) => assert_eq(t, "generic")
        _ => assert_true(false)
      }
      match obj.get("base") {
        Some(Json::String(base)) => assert_eq(base, "Array")
        _ => assert_true(false)
      }
      match obj.get("typeArguments") {
        Some(Json::Array(args)) => assert_eq(args.length(), 1)
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
  
  // Promise<number>
  let promise_number = ts().promise(ts().number()).build()
  match promise_number {
    Json::Object(obj) => {
      match obj.get("type") {
        Some(Json::String(t)) => assert_eq(t, "promise")
        _ => assert_true(false)
      }
      assert_true(obj.contains("resolves"))
    }
    _ => assert_true(false)
  }
}

test "function_type" {
  // (x: string) => number
  let func = ts().func(
    [("x", ts().string(), false)],
    ts().number()
  ).build()
  
  match func {
    Json::Object(obj) => {
      match obj.get("type") {
        Some(Json::String(t)) => assert_eq(t, "function")
        _ => assert_true(false)
      }
      
      match obj.get("parameters") {
        Some(Json::Array(params)) => assert_eq(params.length(), 1)
        _ => assert_true(false)
      }
      
      assert_true(obj.contains("returns"))
    }
    _ => assert_true(false)
  }
}

test "generic_function" {
  // <T>(x: T) => T
  let identity = ts().generic_func(
    [("T", None, None)],
    [("x", ts().type_param("T"), false)],
    ts().type_param("T")
  ).build()
  
  match identity {
    Json::Object(obj) => {
      match obj.get("type") {
        Some(Json::String(t)) => assert_eq(t, "function")
        _ => assert_true(false)
      }
      
      match obj.get("typeParameters") {
        Some(Json::Array(type_params)) => {
          assert_eq(type_params.length(), 1)
          match type_params[0] {
            Json::Object(tp_obj) => {
              match tp_obj.get("name") {
                Some(Json::String(name)) => assert_eq(name, "T")
                _ => assert_true(false)
              }
            }
            _ => assert_true(false)
          }
        }
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

test "generic_with_constraint" {
  // <T extends string>(x: T) => T
  let constrained = ts().generic_func(
    [("T", Some(ts().string()), None)],
    [("x", ts().type_param("T"), false)],
    ts().type_param("T")
  ).build()
  
  match constrained {
    Json::Object(obj) => {
      match obj.get("typeParameters") {
        Some(Json::Array(type_params)) => {
          match type_params[0] {
            Json::Object(tp_obj) => {
              assert_true(tp_obj.contains("constraint"))
              match tp_obj.get("constraint") {
                Some(Json::Object(constraint)) => {
                  assert_true(constraint.contains("extends"))
                }
                _ => assert_true(false)
              }
            }
            _ => assert_true(false)
          }
        }
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

test "async_function" {
  // async (id: string) => Promise<User>
  let async_func = ts().async_func(
    [("id", ts().string(), false)],
    ts().record(ts().string(), ts().any())
  ).build()
  
  match async_func {
    Json::Object(obj) => {
      match obj.get("type") {
        Some(Json::String(t)) => assert_eq(t, "async-function")
        _ => assert_true(false)
      }
      
      assert_true(obj.contains("parameters"))
      assert_true(obj.contains("returns"))
    }
    _ => assert_true(false)
  }
}

test "conditional_type" {
  // T extends string ? number : boolean
  let conditional = ts().conditional(
    ts().type_param("T"),
    ts().string(),
    ts().number(),
    ts().boolean()
  ).build()
  
  match conditional {
    Json::Object(obj) => {
      match obj.get("type") {
        Some(Json::String(t)) => assert_eq(t, "conditional")
        _ => assert_true(false)
      }
      
      assert_true(obj.contains("check"))
      assert_true(obj.contains("extends"))
      assert_true(obj.contains("trueType"))
      assert_true(obj.contains("falseType"))
    }
    _ => assert_true(false)
  }
}

test "utility_types" {
  // Partial<T>
  let partial = ts().partial(ts().type_param("T")).build()
  match partial {
    Json::Object(obj) => {
      match obj.get("type") {
        Some(Json::String(t)) => assert_eq(t, "utility")
        _ => assert_true(false)
      }
      match obj.get("name") {
        Some(Json::String(name)) => assert_eq(name, "Partial")
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
  
  // Pick<T, K>
  let pick = ts().pick(
    ts().type_param("T"),
    ts().type_param("K")
  ).build()
  match pick {
    Json::Object(obj) => {
      match obj.get("name") {
        Some(Json::String(name)) => assert_eq(name, "Pick")
        _ => assert_true(false)
      }
      match obj.get("typeArguments") {
        Some(Json::Array(args)) => assert_eq(args.length(), 2)
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

test "tuple_type" {
  // [string, number, boolean]
  let tuple = ts().tuple([
    ts().string(),
    ts().number(),
    ts().boolean()
  ]).build()
  
  match tuple {
    Json::Object(obj) => {
      match obj.get("type") {
        Some(Json::String(t)) => assert_eq(t, "tuple")
        _ => assert_true(false)
      }
      match obj.get("elements") {
        Some(Json::Array(elems)) => assert_eq(elems.length(), 3)
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

test "keyof_typeof" {
  // keyof T
  let keyof_t = ts().keyof(ts().type_param("T")).build()
  match keyof_t {
    Json::Object(obj) => {
      match obj.get("type") {
        Some(Json::String(t)) => assert_eq(t, "keyof")
        _ => assert_true(false)
      }
      assert_true(obj.contains("target"))
    }
    _ => assert_true(false)
  }
  
  // typeof myVar
  let typeof_var = ts().type_of("myVar").build()
  match typeof_var {
    Json::Object(obj) => {
      match obj.get("type") {
        Some(Json::String(t)) => assert_eq(t, "typeof")
        _ => assert_true(false)
      }
      match obj.get("target") {
        Some(Json::String(target)) => assert_eq(target, "myVar")
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}