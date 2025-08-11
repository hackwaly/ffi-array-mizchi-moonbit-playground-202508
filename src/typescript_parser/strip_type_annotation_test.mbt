// TypeScript型アノテーション除去のテスト

test "strip_type_annotations_simple_function" {
  let func = FunctionDeclaration::{
    name: "add",
    params: [
      Parameter::{ name: "a", type_: Type::Number, optional: false, rest: false },
      Parameter::{ name: "b", type_: Type::Number, optional: false, rest: false }
    ],
    return_type: Type::Number,
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
      Parameter::{ name: "url", type_: String, optional: false, rest: false }
    ],
    return_type: TypeReference("Promise", [String]),
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
      Parameter::{ name: "numbers", type_: Number, optional: false, rest: true }
    ],
    return_type: Number,
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
      Parameter::{ name: "name", type_: String, optional: false, rest: false },
      Parameter::{ name: "title", type_: String, optional: true, rest: false }
    ],
    return_type: String,
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
      Parameter::{ name: "x", type_: Number, optional: false, rest: false },
      Parameter::{ name: "y", type_: Number, optional: false, rest: false }
    ],
    return_type: Number,
    declare: false,
    is_async: false
  }
  
  let binding = generate_function_binding(func, inline_implementation=Some(true))
  inspect(binding.contains("extern \"js\" fn multiply(x : Double, y : Double) -> Double = #|")
  inspect(binding.contains("multiply(x, y) {")
  inspect(binding.contains("// Implementation would go here")
}

test "generate_function_binding_reference_only" {
  let func = FunctionDeclaration::{
    name: "divide",
    params: [
      Parameter::{ name: "a", type_: Number, optional: false, rest: false },
      Parameter::{ name: "b", type_: Number, optional: false, rest: false }
    ],
    return_type: Number,
    declare: false,
    is_async: false
  }
  
  let binding = generate_function_binding(func, inline_implementation=Some(false))
  inspect(binding, content="extern \"js\" fn divide(a : Double, b : Double) -> Double = #|divide|#\n")
}