// Tests for WIT to MoonBit code generation

test "generate simple interface" {
  let wit = """
interface greeter {
  greet: func(name: string) -> string;
}
"""
  
  let doc = parse_wit(wit).unwrap()
  let moonbit_code = generate_moonbit(doc)
  
  inspect!(moonbit_code.contains("pub fn greet"), content="true")
  inspect!(moonbit_code.contains("name : String"), content="true")
  inspect!(moonbit_code.contains("-> String"), content="true")
}

test "generate record type" {
  let wit = """
interface types {
  type person = record {
    name: string,
    age: u32,
    active: bool,
  };
}
"""
  
  let doc = parse_wit(wit).unwrap()
  let moonbit_code = generate_moonbit(doc)
  
  inspect!(moonbit_code.contains("pub struct Person"), content="true")
  inspect!(moonbit_code.contains("name : String"), content="true")
  inspect!(moonbit_code.contains("age : UInt"), content="true")
  inspect!(moonbit_code.contains("active : Bool"), content="true")
  inspect!(moonbit_code.contains("derive(Debug, Show, Eq)"), content="true")
}

test "generate enum type" {
  let wit = """
interface types {
  type status = enum {
    pending,
    in-progress,
    completed,
  };
}
"""
  
  let doc = parse_wit(wit).unwrap()
  let moonbit_code = generate_moonbit(doc)
  
  inspect!(moonbit_code.contains("pub enum Status"), content="true")
  inspect!(moonbit_code.contains("Pending"), content="true")
  inspect!(moonbit_code.contains("InProgress"), content="true")
  inspect!(moonbit_code.contains("Completed"), content="true")
}

test "generate variant type" {
  let wit = """
interface types {
  type result = variant {
    success(string),
    error(u32),
  };
}
"""
  
  let doc = parse_wit(wit).unwrap()
  let moonbit_code = generate_moonbit(doc)
  
  inspect!(moonbit_code.contains("pub enum Result"), content="true")
  inspect!(moonbit_code.contains("Success(String)"), content="true")
  inspect!(moonbit_code.contains("Error(UInt)"), content="true")
}

test "generate flags type" {
  let wit = """
interface types {
  type permissions = flags {
    read,
    write,
    execute,
  };
}
"""
  
  let doc = parse_wit(wit).unwrap()
  let moonbit_code = generate_moonbit(doc)
  
  inspect!(moonbit_code.contains("pub struct Permissions"), content="true")
  inspect!(moonbit_code.contains("read : Bool"), content="true")
  inspect!(moonbit_code.contains("write : Bool"), content="true")
  inspect!(moonbit_code.contains("execute : Bool"), content="true")
}

test "generate resource type" {
  let wit = """
interface resources {
  resource file {
    constructor(path: string);
    read: method() -> list<u8>;
    write: method(data: list<u8>) -> result<u32, string>;
  }
}
"""
  
  let doc = parse_wit(wit).unwrap()
  let moonbit_code = generate_moonbit(doc)
  
  inspect!(moonbit_code.contains("pub struct File"), content="true")
  inspect!(moonbit_code.contains("handle : Int"), content="true")
  inspect!(moonbit_code.contains("pub fn File::new(path : String) -> File"), content="true")
  inspect!(moonbit_code.contains("pub fn read(self : File) -> Array[UInt]"), content="true")
  inspect!(moonbit_code.contains("pub fn write(self : File, data : Array[UInt]) -> Result[UInt, String]"), content="true")
}

test "generate world with imports and exports" {
  let wit = """
world app {
  import log: func(message: string);
  export run: func() -> result<string, string>;
}
"""
  
  let doc = parse_wit(wit).unwrap()
  let moonbit_code = generate_moonbit(doc)
  
  inspect!(moonbit_code.contains("pub struct App"), content="true")
  inspect!(moonbit_code.contains("log : (String) -> Unit"), content="true")
  inspect!(moonbit_code.contains("pub fn App::run() -> Result[String, String]"), content="true")
}

test "type conversion mappings" {
  // Test primitive types
  inspect!(type_to_moonbit(Type::Bool), content="Bool")
  inspect!(type_to_moonbit(Type::S32), content="Int")
  inspect!(type_to_moonbit(Type::S64), content="Int64")
  inspect!(type_to_moonbit(Type::U32), content="UInt")
  inspect!(type_to_moonbit(Type::U64), content="UInt64")
  inspect!(type_to_moonbit(Type::F32), content="Float")
  inspect!(type_to_moonbit(Type::F64), content="Double")
  inspect!(type_to_moonbit(Type::String), content="String")
  
  // Test compound types
  inspect!(type_to_moonbit(Type::List(Type::String)), content="Array[String]")
  inspect!(type_to_moonbit(Type::Option(Type::U32)), content="Option[UInt]")
  
  let result_type = Type::Result { ok: Some(Type::String), err: Some(Type::U32) }
  inspect!(type_to_moonbit(result_type), content="Result[String, UInt]")
  
  let tuple_type = Type::Tuple([Type::String, Type::U32, Type::Bool])
  inspect!(type_to_moonbit(tuple_type), content="(String, UInt, Bool)")
}

test "identifier sanitization" {
  // Kebab-case to PascalCase
  inspect!(sanitize_identifier("my-type"), content="MyType")
  inspect!(sanitize_identifier("long-type-name"), content="LongTypeName")
  inspect!(sanitize_identifier("simple"), content="simple")
  
  // Function names to camelCase
  inspect!(function_name_to_moonbit("get-value"), content="getValue")
  inspect!(function_name_to_moonbit("set-property-value"), content="setPropertyValue")
  inspect!(function_name_to_moonbit("simple"), content="simple")
}

test "generate complex types" {
  let wit = """
interface complex {
  type data = list<tuple<string, option<u32>>>;
  process: func(input: data) -> result<list<string>, string>;
}
"""
  
  let doc = parse_wit(wit).unwrap()
  let moonbit_code = generate_moonbit(doc)
  
  inspect!(moonbit_code.contains("pub type Data = Array[(String, Option[UInt])]"), content="true")
  inspect!(moonbit_code.contains("pub fn process(input : Data) -> Result[Array[String], String]"), content="true")
}