// TypeScript型アノテーション除去のテスト

test "strip_type_annotations_simple_function" {
  let func = FunctionDeclaration::{
    name: "add",
    params: [
      { name: "a", type_: @typescript_parser.Number, optional: false, rest: false },
      { name: "b", type_: @typescript_parser.Number, optional: false, rest: false }
    ],
    return_type: @typescript_parser.Number,
    declare: false,
    is_async: false
  }
  
  let result = strip_type_annotations(func)
  inspect(result, content="add(a, b)")
}

test "strip_type_annotations_async_function" {
  let func = FunctionDeclaration::{
    name: "fetchData",
    params: [
      { name: "url", type_: @typescript_parser.String, optional: false, rest: false }
    ],
    return_type: @typescript_parser.TypeReference("Promise", [@typescript_parser.String]),
    declare: false,
    is_async: true
  }
  
  let result = strip_type_annotations(func)
  inspect(result, content="async fetchData(url)")
}

test "strip_type_annotations_rest_parameter" {
  let func = FunctionDeclaration::{
    name: "sum",
    params: [
      { name: "numbers", type_: @typescript_parser.Number, optional: false, rest: true }
    ],
    return_type: @typescript_parser.Number,
    declare: false,
    is_async: false
  }
  
  let result = strip_type_annotations(func)
  inspect(result, content="sum(...numbers)")
}

test "strip_type_annotations_optional_parameter" {
  let func = FunctionDeclaration::{
    name: "greet",
    params: [
      { name: "name", type_: @typescript_parser.String, optional: false, rest: false },
      { name: "title", type_: @typescript_parser.String, optional: true, rest: false }
    ],
    return_type: @typescript_parser.String,
    declare: false,
    is_async: false
  }
  
  // Note: 現在の実装ではoptionalマーカーは除去されるが、
  // JavaScriptでは関数の引数はすべてoptionalなので問題ない
  let result = strip_type_annotations(func)
  inspect(result, content="greet(name, title)")
}

test "generate_function_binding_with_inline_implementation" {
  let func = FunctionDeclaration::{
    name: "multiply",
    params: [
      { name: "x", type_: @typescript_parser.Number, optional: false, rest: false },
      { name: "y", type_: @typescript_parser.Number, optional: false, rest: false }
    ],
    return_type: @typescript_parser.Number,
    declare: false,
    is_async: false
  }
  
  let binding = generate_function_binding(func, inline_implementation=Some(true))
  inspect(binding.contains("extern \"js\" fn multiply(x : Double, y : Double) -> Double = #|"), content="true")
  inspect(binding.contains("multiply(x, y) {"), content="true")
  inspect(binding.contains("// Implementation would go here"), content="true")
}

test "generate_function_binding_reference_only" {
  let func = FunctionDeclaration::{
    name: "divide",
    params: [
      { name: "a", type_: @typescript_parser.Number, optional: false, rest: false },
      { name: "b", type_: @typescript_parser.Number, optional: false, rest: false }
    ],
    return_type: @typescript_parser.Number,
    declare: false,
    is_async: false
  }
  
  let binding = generate_function_binding(func, inline_implementation=Some(false))
  inspect(binding, content="extern \"js\" fn divide(a : Double, b : Double) -> Double = #|divide|#\n")
}
