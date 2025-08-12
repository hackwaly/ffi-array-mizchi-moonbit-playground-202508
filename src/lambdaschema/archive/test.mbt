test "basic_function_type" {
  let func = FunctionBuilder::new()
    .with_name("add")
    .with_parameter("a", LambdaType::number(), false, None)
    .with_parameter("b", LambdaType::number(), false, None)
    .with_return_type(LambdaType::number())
    .build()
  
  let func_type = Function(func)
  assert_eq(func.name, Some("add"))
  assert_eq(func.parameters.length(), 2)
  assert_eq(func.parameters[0].name, "a")
  assert_eq(func.parameters[1].name, "b")
}

test "generic_function" {
  let func = FunctionBuilder::new()
    .with_name("identity")
    .with_type_parameter("T", None)
    .with_parameter("value", TypeParameter("T"), false, None)
    .with_return_type(TypeParameter("T"))
    .build()
  
  let func_type = Function(func)
  assert_eq(func.type_parameters.length(), 1)
  assert_eq(func.type_parameters[0].name, "T")
}

test "type_instantiation" {
  let generic_array = Named("Array", [TypeParameter("T")])
  let type_args = Map::from_array([("T", LambdaType::string())])
  let instantiated = generic_array.instantiate(type_args)
  
  match instantiated {
    Named(name, args) => {
      assert_eq(name, "Array")
      assert_eq(args.length(), 1)
      match args[0] {
        Schema(_) => assert_true(true)
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

test "subtype_checking" {
  let string_type = LambdaType::string()
  let any_type = Any
  let never_type = Never
  
  assert_true(string_type.is_subtype_of(any_type))
  assert_true(never_type.is_subtype_of(string_type))
  assert_false(any_type.is_subtype_of(string_type))
}

test "type_registry" {
  let registry = TypeRegistry::new()
  
  let my_type = LambdaType::string()
  registry.register("MyType", my_type)
  
  match registry.resolve("MyType") {
    Some(t) => match (t, my_type) {
      (Schema(s1), Schema(s2)) => assert_true(true)
      _ => assert_true(false)
    }
    None => assert_true(false)
  }
}

test "constraint_checking" {
  let string_type = LambdaType::string()
  let constraint = Extends(string_type)
  
  assert_true(check_type_constraint(string_type, constraint))
  assert_true(check_type_constraint(Never, constraint))
  assert_false(check_type_constraint(Any, constraint))
}

test "union_types" {
  let string_or_number = LambdaType::union([
    LambdaType::string(),
    LambdaType::number()
  ])
  
  match string_or_number {
    Union(types) => {
      assert_eq(types.length(), 2)
    }
    _ => assert_true(false)
  }
}

test "function_with_optional_params" {
  let func = FunctionBuilder::new()
    .with_name("greet")
    .with_parameter("name", LambdaType::string(), false, None)
    .with_parameter("greeting", LambdaType::string(), true, None)
    .with_return_type(LambdaType::string())
    .build()
  
  assert_eq(func.parameters[1].optional, true)
}

test "array_and_tuple_types" {
  let string_array = LambdaType::array(LambdaType::string())
  let coordinate = LambdaType::tuple([
    LambdaType::number(),
    LambdaType::number()
  ])
  
  match string_array {
    Array(elem) => {
      match elem {
        Schema(_) => assert_true(true)
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
  
  match coordinate {
    Tuple(elems) => {
      assert_eq(elems.length(), 2)
    }
    _ => assert_true(false)
  }
}

test "type_parameter_with_constraint" {
  let type_param : TypeParameter = {
    name: "T",
    constraint: Some(Extends(LambdaType::string()))
  }
  
  assert_eq(type_param.name, "T")
  match type_param.constraint {
    Some(Extends(_)) => assert_true(true)
    _ => assert_true(false)
  }
}

test "complex_generic_function" {
  let func = FunctionBuilder::new()
    .with_name("map")
    .with_type_parameter("T", None)
    .with_type_parameter("U", None)
    .with_parameter("array", 
      Named("Array", [TypeParameter("T")]), false, None)
    .with_parameter("mapper",
      LambdaType::function(
        [{ name: "item", param_type: TypeParameter("T"), optional: false, default_value: None }],
        TypeParameter("U")
      ), false, None)
    .with_return_type(Named("Array", [TypeParameter("U")]))
    .build()
  
  assert_eq(func.type_parameters.length(), 2)
  assert_eq(func.parameters.length(), 2)
}