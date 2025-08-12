// コード生成のテスト

test "typescript_basic_types" {
  // string型
  let str_type = UniversalType::String
  let ts_str = generate_typescript(str_type)
  assert_eq(ts_str, "string")
  
  // number型
  let num_type = UniversalType::Number
  let ts_num = generate_typescript(num_type)
  assert_eq(ts_num, "number")
  
  // boolean型
  let bool_type = UniversalType::Boolean
  let ts_bool = generate_typescript(bool_type)
  assert_eq(ts_bool, "boolean")
  
  // null型
  let null_type = UniversalType::Null
  let ts_null = generate_typescript(null_type)
  assert_eq(ts_null, "null")
  
  // undefined型
  let undef_type = UniversalType::Undefined
  let ts_undef = generate_typescript(undef_type)
  assert_eq(ts_undef, "undefined")
}

test "typescript_array_and_tuple" {
  // Array<string>
  let array_type = UniversalType::Array(UniversalType::String)
  let ts_array = generate_typescript(array_type)
  assert_eq(ts_array, "string[]")
  
  // [string, number, boolean]
  let tuple_type = UniversalType::Tuple([UniversalType::String, UniversalType::Number, UniversalType::Boolean])
  let ts_tuple = generate_typescript(tuple_type)
  assert_eq(ts_tuple, "[string, number, boolean]")
}

test "typescript_union_and_intersection" {
  // string | number
  let union_type = UniversalType::Union([UniversalType::String, UniversalType::Number])
  let ts_union = generate_typescript(union_type)
  assert_eq(ts_union, "(string | number)")
  
  // A & B (仮想的な例)
  let intersection_type = UniversalType::Intersection([
    UniversalType::TypeReference("A"),
    UniversalType::TypeReference("B")
  ])
  let ts_intersection = generate_typescript(intersection_type)
  assert_eq(ts_intersection, "(A & B)")
}

test "typescript_function_type" {
  // (x: string) => number
  let func_sig : FunctionSignature = {
    type_parameters: [],
    parameters: [{
      name: "x",
      param_type: UniversalType::String,
      optional: false,
      default_value: None,
      is_rest: false
    }],
    return_type: UniversalType::Number,
    is_async: false,
    throws: None
  }
  let func_type = UniversalType::Function(func_sig)
  let ts_func = generate_typescript(func_type)
  assert_eq(ts_func, "(x: string) => number")
}

test "typescript_generic_function" {
  // <T>(x: T) => T
  let identity_sig : FunctionSignature = {
    type_parameters: [{
      name: "T",
      constraint: None,
      default: None,
      variance: None
    }],
    parameters: [{
      name: "x",
      param_type: UniversalType::TypeParameter("T", None),
      optional: false,
      default_value: None,
      is_rest: false
    }],
    return_type: UniversalType::TypeParameter("T", None),
    is_async: false,
    throws: None
  }
  let identity_type = UniversalType::Function(identity_sig)
  let ts_identity = generate_typescript(identity_type)
  assert_eq(ts_identity, "<T>(x: T) => T")
}

test "typescript_async_function" {
  // async (id: string) => Promise<User>
  let async_sig : FunctionSignature = {
    type_parameters: [],
    parameters: [{
      name: "id",
      param_type: UniversalType::String,
      optional: false,
      default_value: None,
      is_rest: false
    }],
    return_type: UniversalType::TypeReference("User"),
    is_async: true,
    throws: None
  }
  let async_type = UniversalType::Function(async_sig)
  let ts_async = generate_typescript(async_type)
  assert_eq(ts_async, "(id: string) => Promise<User>")
}

test "moonbit_basic_types" {
  // String型
  let str_type = UniversalType::String
  let mb_str = generate_moonbit(str_type)
  assert_eq(mb_str, "String")
  
  // Int型
  let int_type = UniversalType::Integer
  let mb_int = generate_moonbit(int_type)
  assert_eq(mb_int, "Int")
  
  // Bool型
  let bool_type = UniversalType::Boolean
  let mb_bool = generate_moonbit(bool_type)
  assert_eq(mb_bool, "Bool")
  
  // Unit型（void/null/undefinedの代替）
  let void_type = UniversalType::Void
  let mb_void = generate_moonbit(void_type)
  assert_eq(mb_void, "Unit")
}

test "moonbit_collections" {
  // Array[UniversalType::String]
  let array_type = UniversalType::Array(UniversalType::String)
  let mb_array = generate_moonbit(array_type)
  assert_eq(mb_array, "Array[String]")
  
  // Map[UniversalType::String, Int]
  let map_type = UniversalType::Map(UniversalType::String, UniversalType::Integer)
  let mb_map = generate_moonbit(map_type)
  assert_eq(mb_map, "Map[String, Int]")
  
  // Set[UniversalType::Boolean]
  let set_type = UniversalType::Set(UniversalType::Boolean)
  let mb_set = generate_moonbit(set_type)
  assert_eq(mb_set, "Set[Bool]")
}

test "moonbit_optional" {
  // UniversalType::String?
  let optional_type = UniversalType::Optional(UniversalType::String)
  let mb_optional = generate_moonbit(optional_type)
  assert_eq(mb_optional, "String?")
  
  // Int? (nullable)
  let nullable_type = UniversalType::Nullable(UniversalType::Integer)
  let mb_nullable = generate_moonbit(nullable_type)
  assert_eq(mb_nullable, "Int?")
}

test "python_basic_types" {
  // str型
  let str_type = UniversalType::String
  let py_str = generate_python(str_type)
  assert_eq(py_str, "str")
  
  // int型
  let int_type = UniversalType::Integer
  let py_int = generate_python(int_type)
  assert_eq(py_int, "int")
  
  // bool型
  let bool_type = UniversalType::Boolean
  let py_bool = generate_python(bool_type)
  assert_eq(py_bool, "bool")
  
  // None型
  let none_type = UniversalType::Null
  let py_none = generate_python(none_type)
  assert_eq(py_none, "None")
}

test "python_collections" {
  // List[str]
  let list_type = UniversalType::Array(UniversalType::String)
  let py_list = generate_python(list_type)
  assert_eq(py_list, "List[str]")
  
  // Dict[str, int]
  let dict_type = UniversalType::Map(UniversalType::String, UniversalType::Integer)
  let py_dict = generate_python(dict_type)
  assert_eq(py_dict, "Dict[str, int]")
  
  // Set[bool]
  let set_type = UniversalType::Set(UniversalType::Boolean)
  let py_set = generate_python(set_type)
  assert_eq(py_set, "Set[bool]")
  
  // Tuple[str, int, bool]
  let tuple_type = UniversalType::Tuple([UniversalType::String, UniversalType::Integer, UniversalType::Boolean])
  let py_tuple = generate_python(tuple_type)
  assert_eq(py_tuple, "Tuple[str, int, bool]")
}

test "python_union_and_optional" {
  // str | int
  let union_type = UniversalType::Union([UniversalType::String, UniversalType::Integer])
  let py_union = generate_python(union_type)
  assert_eq(py_union, "str | int")
  
  // Optional[str]
  let optional_type = UniversalType::Optional(UniversalType::String)
  let py_optional = generate_python(optional_type)
  assert_eq(py_optional, "Optional[str]")
  
  // str | None
  let nullable_type = UniversalType::Nullable(UniversalType::String)
  let py_nullable = generate_python(nullable_type)
  assert_eq(py_nullable, "str | None")
}

test "python_callable" {
  // Callable[[str], int]
  let func_sig : FunctionSignature = {
    type_parameters: [],
    parameters: [{
      name: "x",
      param_type: UniversalType::String,
      optional: false,
      default_value: None,
      is_rest: false
    }],
    return_type: UniversalType::Integer,
    is_async: false,
    throws: None
  }
  let func_type = UniversalType::Function(func_sig)
  let py_func = generate_python(func_type)
  assert_eq(py_func, "Callable[[str], int]")
}

test "python_async_callable" {
  // Awaitable[str]
  let async_sig : FunctionSignature = {
    type_parameters: [],
    parameters: [],
    return_type: UniversalType::String,
    is_async: true,
    throws: None
  }
  let async_type = UniversalType::Function(async_sig)
  let py_async = generate_python(async_type)
  assert_eq(py_async, "Callable[[], Awaitable[str]]")
}

test "cross_language_consistency" {
  // 同じ型が各言語で正しく生成されることを確認
  let test_type = UniversalType::Array(UniversalType::Optional(UniversalType::String))
  
  // TypeScript: (string | null | undefined)[]
  let ts_output = generate_typescript(test_type)
  assert_eq(ts_output, "(string | null | undefined)[]")
  
  // MoonBit: Array[UniversalType::String?]
  let mb_output = generate_moonbit(test_type)
  assert_eq(mb_output, "Array[String?]")
  
  // Python: List[Optional[str]]
  let py_output = generate_python(test_type)
  assert_eq(py_output, "List[Optional[str]]")
}

test "literal_types" {
  // TypeScript: "hello"
  let str_literal = UniversalType::StringLiteral("hello")
  let ts_str_lit = generate_typescript(str_literal)
  assert_eq(ts_str_lit, "\"hello\"")
  
  // TypeScript: 42
  let num_literal = UniversalType::NumberLiteral(42.0)
  let ts_num_lit = generate_typescript(num_literal)
  assert_eq(ts_num_lit, "42")
  
  // TypeScript: true
  let bool_literal = UniversalType::BooleanLiteral(true)
  let ts_bool_lit = generate_typescript(bool_literal)
  assert_eq(ts_bool_lit, "true")
  
  // Python: Literal["hello"]
  let py_str_lit = generate_python(str_literal)
  assert_eq(py_str_lit, "Literal[\"hello\"]")
  
  // Python: Literal[42]
  let py_num_lit = generate_python(num_literal)
  assert_eq(py_num_lit, "Literal[42]")
  
  // Python: Literal[True]
  let py_bool_lit = generate_python(bool_literal)
  assert_eq(py_bool_lit, "Literal[True]")
}

test "promise_and_result_types" {
  // TypeScript: Promise<string>
  let promise_type = UniversalType::Promise(UniversalType::String)
  let ts_promise = generate_typescript(promise_type)
  assert_eq(ts_promise, "Promise<string>")
  
  // MoonBit: Result[UniversalType::String, Error]
  let mb_promise = generate_moonbit(promise_type)
  assert_eq(mb_promise, "Result[String, Error]")
  
  // Python: Awaitable[str]
  let py_promise = generate_python(promise_type)
  assert_eq(py_promise, "Awaitable[str]")
  
  // Result型
  let result_type = UniversalType::Result(UniversalType::String, UniversalType::TypeReference("Error"))
  
  // TypeScript: Result<string, Error>
  let ts_result = generate_typescript(result_type)
  assert_eq(ts_result, "Result<string, Error>")
  
  // MoonBit: Result[UniversalType::String, Error]
  let mb_result = generate_moonbit(result_type)
  assert_eq(mb_result, "Result[String, Error]")
  
  // Python: str | Error
  let py_result = generate_python(result_type)
  assert_eq(py_result, "str | Error")
}

test "type_application" {
  // Array<Map<string, number>>
  let nested_type = UniversalType::TypeApplication("Array", [
    UniversalType::TypeApplication("Map", [UniversalType::String, UniversalType::Number])
  ])
  
  // TypeScript
  let ts_nested = generate_typescript(nested_type)
  assert_eq(ts_nested, "Array<Map<string, number>>")
  
  // MoonBit
  let mb_nested = generate_moonbit(nested_type)
  assert_eq(mb_nested, "Array[Map[String, Double]]")
  
  // Python
  let py_nested = generate_python(nested_type)
  assert_eq(py_nested, "Array[Map[str, float]]")
}