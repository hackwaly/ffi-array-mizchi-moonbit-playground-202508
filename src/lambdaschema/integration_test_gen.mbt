// インテグレーションテスト用のコード生成

// 共通の型定義を生成
fn generate_integration_test_types() -> (String, String, String) {
  // User型の定義
  let user_fields = Map::new()
  user_fields.set("id", ObjectField::{
    field_type: UniversalType::String,
    optional: false,
    is_readonly: true,
    description: Some("User ID")
  })
  user_fields.set("name", ObjectField::{
    field_type: UniversalType::String,
    optional: false,
    is_readonly: false,
    description: Some("User name")
  })
  user_fields.set("email", ObjectField::{
    field_type: UniversalType::String,
    optional: false,
    is_readonly: false,
    description: Some("Email address")
  })
  user_fields.set("age", ObjectField::{
    field_type: UniversalType::Integer,
    optional: true,
    is_readonly: false,
    description: Some("User age")
  })
  let user_type = UniversalType::Object(user_fields)
  
  // APIResponse<T>型の定義（ジェネリック）
  let response_fields = Map::new()
  response_fields.set("success", ObjectField::{
    field_type: UniversalType::Boolean,
    optional: false,
    is_readonly: true,
    description: Some("Whether the request was successful")
  })
  response_fields.set("data", ObjectField::{
    field_type: UniversalType::TypeParameter("T", None),
    optional: true,
    is_readonly: true,
    description: Some("Response data")
  })
  response_fields.set("error", ObjectField::{
    field_type: UniversalType::String,
    optional: true,
    is_readonly: true,
    description: Some("Error message")
  })
  
  // 関数型の定義
  let get_user_sig : FunctionSignature = {
    type_parameters: [],
    parameters: [{
      name: "id",
      param_type: UniversalType::String,
      optional: false,
      default_value: None,
      is_rest: false
    }],
    return_type: UniversalType::Promise(user_type),
    is_async: true,
    throws: None
  }
  
  let create_user_sig : FunctionSignature = {
    type_parameters: [],
    parameters: [
      {
        name: "name",
        param_type: UniversalType::String,
        optional: false,
        default_value: None,
        is_rest: false
      },
      {
        name: "email",
        param_type: UniversalType::String,
        optional: false,
        default_value: None,
        is_rest: false
      },
      {
        name: "age",
        param_type: UniversalType::Integer,
        optional: true,
        default_value: None,
        is_rest: false
      }
    ],
    return_type: UniversalType::Promise(user_type),
    is_async: true,
    throws: None
  }
  
  // TypeScript生成
  let ts_code = generate_typescript_integration_code(
    user_type,
    response_fields,
    get_user_sig,
    create_user_sig
  )
  
  // MoonBit生成
  let mb_code = generate_moonbit_integration_code(
    user_type,
    response_fields,
    get_user_sig,
    create_user_sig
  )
  
  // Python生成
  let py_code = generate_python_integration_code(
    user_type,
    response_fields,
    get_user_sig,
    create_user_sig
  )
  
  (ts_code, mb_code, py_code)
}

fn generate_typescript_integration_code(
  user_type : UniversalType,
  response_fields : Map[String, ObjectField],
  get_user_sig : FunctionSignature,
  create_user_sig : FunctionSignature
) -> String {
  let mut code = "// Generated TypeScript Integration Test Code\n\n"
  
  // User interface
  code = code + generate_typescript_interface("User", user_type, true) + "\n\n"
  
  // APIResponse<T> interface (generic)
  code = code + "export interface APIResponse<T> {\n"
  response_fields.each(fn(name, field) {
    let optional = if field.optional { "?" } else { "" }
    let readonly_str = if field.is_readonly { "readonly " } else { "" }
    let field_type_str = if name == "data" {
      "T"
    } else {
      generate_typescript(field.field_type)
    }
    code = code + "  " + readonly_str + name + optional + ": " + field_type_str + ";\n"
  })
  code = code + "}\n\n"
  
  // Function declarations
  code = code + "// API Functions\n"
  code = code + "export async function getUser(id: string): Promise<User> {\n"
  code = code + "  // Implementation would go here\n"
  code = code + "  return {} as User;\n"
  code = code + "}\n\n"
  
  code = code + "export async function createUser(\n"
  code = code + "  name: string,\n"
  code = code + "  email: string,\n"
  code = code + "  age?: number\n"
  code = code + "): Promise<User> {\n"
  code = code + "  // Implementation would go here\n"
  code = code + "  return {} as User;\n"
  code = code + "}\n\n"
  
  // Union type example
  code = code + "// Status type\n"
  code = code + "export type Status = \"pending\" | \"active\" | \"inactive\";\n\n"
  
  // Utility function with generics
  code = code + "// Generic utility function\n"
  code = code + "export function wrapInResponse<T>(data: T, success: boolean = true): APIResponse<T> {\n"
  code = code + "  return {\n"
  code = code + "    success,\n"
  code = code + "    data: success ? data : undefined,\n"
  code = code + "    error: success ? undefined : \"An error occurred\"\n"
  code = code + "  };\n"
  code = code + "}\n"
  
  code
}

fn generate_moonbit_integration_code(
  user_type : UniversalType,
  response_fields : Map[String, ObjectField],
  get_user_sig : FunctionSignature,
  create_user_sig : FunctionSignature
) -> String {
  let mut code = "// Generated MoonBit Integration Test Code\n\n"
  
  // User struct
  code = code + "pub struct User {\n"
  code = code + "  id : String\n"
  code = code + "  mut name : String\n"
  code = code + "  mut email : String\n"
  code = code + "  mut age : Int?\n"
  code = code + "}\n\n"
  
  // APIResponse struct (generic)
  code = code + "pub struct APIResponse[T] {\n"
  code = code + "  success : Bool\n"
  code = code + "  data : T?\n"
  code = code + "  error : String?\n"
  code = code + "}\n\n"
  
  // Status enum (union type alternative)
  code = code + "pub enum Status {\n"
  code = code + "  Pending\n"
  code = code + "  Active\n"
  code = code + "  Inactive\n"
  code = code + "}\n\n"
  
  // Function implementations
  code = code + "// API Functions\n"
  code = code + "pub fn get_user(id : String) -> Result[User, String] {\n"
  code = code + "  // Implementation would go here\n"
  code = code + "  Ok({\n"
  code = code + "    id: id,\n"
  code = code + "    name: \"Test User\",\n"
  code = code + "    email: \"test@example.com\",\n"
  code = code + "    age: Some(25)\n"
  code = code + "  })\n"
  code = code + "}\n\n"
  
  code = code + "pub fn create_user(\n"
  code = code + "  name : String,\n"
  code = code + "  email : String,\n"
  code = code + "  age : Int?\n"
  code = code + ") -> Result[User, String] {\n"
  code = code + "  // Implementation would go here\n"
  code = code + "  Ok({\n"
  code = code + "    id: \"generated-id\",\n"
  code = code + "    name: name,\n"
  code = code + "    email: email,\n"
  code = code + "    age: age\n"
  code = code + "  })\n"
  code = code + "}\n\n"
  
  // Generic utility function
  code = code + "// Generic utility function\n"
  code = code + "pub fn wrap_in_response[T](\n"
  code = code + "  data : T?,\n"
  code = code + "  success : Bool\n"
  code = code + ") -> APIResponse[T] {\n"
  code = code + "  {\n"
  code = code + "    success: success,\n"
  code = code + "    data: data,\n"
  code = code + "    error: if success { None } else { Some(\"An error occurred\") }\n"
  code = code + "  }\n"
  code = code + "}\n\n"
  
  // Test function
  code = code + "test \"integration_test\" {\n"
  code = code + "  // Test user creation\n"
  code = code + "  let result = create_user(\"Alice\", \"alice@example.com\", Some(30))\n"
  code = code + "  match result {\n"
  code = code + "    Ok(user) => {\n"
  code = code + "      assert_eq(user.name, \"Alice\")\n"
  code = code + "      assert_eq(user.email, \"alice@example.com\")\n"
  code = code + "    }\n"
  code = code + "    Err(e) => assert_true(false)\n"
  code = code + "  }\n"
  code = code + "  \n"
  code = code + "  // Test response wrapper\n"
  code = code + "  let response = wrap_in_response(Some(42), true)\n"
  code = code + "  assert_eq(response.success, true)\n"
  code = code + "  match response.data {\n"
  code = code + "    Some(value) => assert_eq(value, 42)\n"
  code = code + "    None => assert_true(false)\n"
  code = code + "  }\n"
  code = code + "}\n"
  
  code
}

fn generate_python_integration_code(
  user_type : UniversalType,
  response_fields : Map[String, ObjectField],
  get_user_sig : FunctionSignature,
  create_user_sig : FunctionSignature
) -> String {
  let mut code = "# Generated Python Integration Test Code\n\n"
  code = code + "from typing import Optional, TypeVar, Generic, Literal\n"
  code = code + "from typing_extensions import TypedDict\n"
  code = code + "from dataclasses import dataclass\n"
  code = code + "import asyncio\n\n"
  
  // User TypedDict
  code = code + "class User(TypedDict):\n"
  code = code + "    id: str\n"
  code = code + "    name: str\n"
  code = code + "    email: str\n"
  code = code + "    age: Optional[int]\n\n"
  
  // APIResponse Generic class
  code = code + "T = TypeVar('T')\n\n"
  code = code + "@dataclass\n"
  code = code + "class APIResponse(Generic[T]):\n"
  code = code + "    success: bool\n"
  code = code + "    data: Optional[T]\n"
  code = code + "    error: Optional[str]\n\n"
  
  // Status type (Literal union)
  code = code + "Status = Literal[\"pending\", \"active\", \"inactive\"]\n\n"
  
  // Async functions
  code = code + "# API Functions\n"
  code = code + "async def get_user(id: str) -> User:\n"
  code = code + "    \"\"\"Fetch a user by ID\"\"\"\n"
  code = code + "    # Implementation would go here\n"
  code = code + "    return {\n"
  code = code + "        \"id\": id,\n"
  code = code + "        \"name\": \"Test User\",\n"
  code = code + "        \"email\": \"test@example.com\",\n"
  code = code + "        \"age\": 25\n"
  code = code + "    }\n\n"
  
  code = code + "async def create_user(\n"
  code = code + "    name: str,\n"
  code = code + "    email: str,\n"
  code = code + "    age: Optional[int] = None\n"
  code = code + ") -> User:\n"
  code = code + "    \"\"\"Create a new user\"\"\"\n"
  code = code + "    # Implementation would go here\n"
  code = code + "    return {\n"
  code = code + "        \"id\": \"generated-id\",\n"
  code = code + "        \"name\": name,\n"
  code = code + "        \"email\": email,\n"
  code = code + "        \"age\": age\n"
  code = code + "    }\n\n"
  
  // Generic utility function
  code = code + "# Generic utility function\n"
  code = code + "def wrap_in_response(data: T, success: bool = True) -> APIResponse[T]:\n"
  code = code + "    \"\"\"Wrap data in an API response\"\"\"\n"
  code = code + "    return APIResponse(\n"
  code = code + "        success=success,\n"
  code = code + "        data=data if success else None,\n"
  code = code + "        error=None if success else \"An error occurred\"\n"
  code = code + "    )\n\n"
  
  // Test code
  code = code + "# Test code\n"
  code = code + "async def test_integration():\n"
  code = code + "    # Test user creation\n"
  code = code + "    user = await create_user(\"Alice\", \"alice@example.com\", 30)\n"
  code = code + "    assert user[\"name\"] == \"Alice\"\n"
  code = code + "    assert user[\"email\"] == \"alice@example.com\"\n"
  code = code + "    \n"
  code = code + "    # Test response wrapper\n"
  code = code + "    response = wrap_in_response(42, True)\n"
  code = code + "    assert response.success == True\n"
  code = code + "    assert response.data == 42\n"
  code = code + "    \n"
  code = code + "    print(\"All tests passed!\")\n\n"
  
  code = code + "if __name__ == \"__main__\":\n"
  code = code + "    asyncio.run(test_integration())\n"
  
  code
}

// メイン関数として実行
pub fn generate_and_save_integration_test() -> Unit {
  let (ts_code, mb_code, py_code) = generate_integration_test_types()
  
  // TypeScriptコードを出力
  println("=== TYPESCRIPT CODE START ===")
  println(ts_code)
  println("=== TYPESCRIPT CODE END ===")
  println("")
  
  // MoonBitコードを出力
  println("=== MOONBIT CODE START ===")
  println(mb_code)
  println("=== MOONBIT CODE END ===")
  println("")
  
  // Pythonコードを出力
  println("=== PYTHON CODE START ===")
  println(py_code)
  println("=== PYTHON CODE END ===")
}