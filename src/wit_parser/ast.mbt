// WIT (WebAssembly Interface Types) AST definitions

// Top-level WIT document
///|
pub struct WitDocument {
  package_name : String?
  items : Array[TopLevelItem]
} derive(Show, Eq)

// Top-level items in a WIT document

///|
pub enum TopLevelItem {
  Interface(Interface)
  World(World)
  Use(UseItem)
} derive(Show, Eq)

// Interface definition

///|
pub struct Interface {
  name : String
  items : Array[InterfaceItem]
} derive(Show, Eq)

// Items within an interface

///|
pub enum InterfaceItem {
  Use(UseItem)
  Type(TypeDef)
  Function(Function)
  Export(String) // Export another interface
} derive(Show, Eq)

// World definition

///|
pub struct World {
  name : String
  items : Array[WorldItem]
} derive(Show, Eq)

// Items within a world

///|
pub enum WorldItem {
  Use(UseItem)
  Type(TypeDef)
  Import(Import)
  Export(Export)
} derive(Show, Eq)

// Import declaration

///|
pub struct Import {
  name : String
  kind : ImportKind
} derive(Show, Eq)

///|
pub enum ImportKind {
  Function(Function)
  Interface(String) // Interface name
} derive(Show, Eq)

// Export declaration

///|
pub struct Export {
  name : String
  kind : ExportKind
} derive(Show, Eq)

///|
pub enum ExportKind {
  Function(Function)
  Interface(String) // Interface name
} derive(Show, Eq)

// Use statement

///|
pub struct UseItem {
  path : String // e.g., "wasi:io/streams"
  items : Array[UseItemSpec]
} derive(Show, Eq)

///|
pub enum UseItemSpec {
  All // use *
  Named(Array[String]) // use { a, b, c }
} derive(Show, Eq)

// Type definition

///|
pub struct TypeDef {
  name : String
  def : TypeDefKind
} derive(Show, Eq)

///|
pub enum TypeDefKind {
  Alias(Type)
  Record(Record)
  Enum(Enum)
  Flags(Flags)
  Variant(Variant)
  Resource(Resource)
} derive(Show, Eq)

// Record type

///|
pub struct Record {
  fields : Array[Field]
} derive(Show, Eq)

///|
pub struct Field {
  name : String
  typ : Type
} derive(Show, Eq)

// Enum type

///|
pub struct Enum {
  cases : Array[String]
} derive(Show, Eq)

// Flags type

///|
pub struct Flags {
  flags : Array[String]
} derive(Show, Eq)

// Variant type

///|
pub struct Variant {
  cases : Array[VariantCase]
} derive(Show, Eq)

///|
pub struct VariantCase {
  name : String
  typ : Type?
} derive(Show, Eq)

// Resource type

///|
pub struct Resource {
  methods : Array[ResourceMethod]
} derive(Show, Eq)

///|
pub struct ResourceMethod {
  name : String
  kind : MethodKind
} derive(Show, Eq)

///|
pub enum MethodKind {
  Constructor(Array[Param])
  Method(Function)
  Static(Function)
} derive(Show, Eq)

// Function definition

///|
pub struct Function {
  name : String
  params : Array[Param]
  results : FunctionResult
} derive(Show, Eq)

///|
pub struct Param {
  name : String
  typ : Type
} derive(Show, Eq)

///|
pub enum FunctionResult {
  None
  Single(Type)
  Named(Array[Param])
} derive(Show, Eq)

// Types

///|
pub enum Type {
  // Primitive types
  Bool
  S8
  S16
  S32
  S64
  U8
  U16
  U32
  U64
  F32
  F64
  Char
  String

  // Compound types
  List(Type)
  Option(Type)
  Result(Type?, Type?) // ok type, err type
  Tuple(Array[Type])

  // Named type reference
  Named(String)

  // Borrow (for resource types)
  Borrow(String)

  // Own (for owned resource types)
  Own(String)
} derive(Show, Eq)

// Manual implementations for Show and Eq for Type to satisfy derives in other AST types
// impl Show for Type {
//   fn to_string(self: Type) -> String {
//     match self {
//      Type::Bool => "Bool"
//      Type::S8 => "S8"
//      Type::S16 => "S16"
//      Type::S32 => "S32"
//      Type::S64 => "S64"
//      Type::U8 => "U8"
//      Type::U16 => "U16"
//      Type::U32 => "U32"
//      Type::U64 => "U64"
//      Type::F32 => "F32"
//      Type::F64 => "F64"
//      Type::Char => "Char"
//      Type::String => "String"
//      Type::List(t) => "List[" + t.to_string() + "]"
//      Type::Option(t) => "Option[" + t.to_string() + "]"
//      Type::Result(ok, err) => {
//        let ok_s = match ok {
//          Some(t) => t.to_string()
//          None => ""
//        }
//        let err_s = match err {
//          Some(t) => t.to_string()
//          None => ""
//        }
//        "Result[" + ok_s + ", " + err_s + "]"
//      }
//      Type::Tuple(ts) => {
//        let parts = ts.map(fn(x) { x.to_string() })
//        "(" + parts.join(", ") + ")"
//      }
//      Type::Named(n) => "Named(" + n + ")"
//       Type::Borrow(n) => "Borrow(" + n + ")"
//       Type::Own(n) => "Own(" + n + ")"
//     }
//   }
// }

// Helper constructors

///|
pub fn WitDocument::new() -> WitDocument {
  { package_name: None, items: [] }
}

///|
pub fn WitDocument::with_package(name : String) -> WitDocument {
  { package_name: Some(name), items: [] }
}

///|
pub fn Interface::new(name : String) -> Interface {
  { name, items: [] }
}

///|
pub fn World::new(name : String) -> World {
  { name, items: [] }
}

///|
pub fn Function::new(name : String) -> Function {
  { name, params: [], results: FunctionResult::None }
}

///|
pub fn Record::new() -> Record {
  { fields: [] }
}

///|
pub fn Enum::new() -> Enum {
  { cases: [] }
}

///|
pub fn Flags::new() -> Flags {
  { flags: [] }
}

///|
pub fn Variant::new() -> Variant {
  { cases: [] }
}

///|
pub fn Resource::new() -> Resource {
  { methods: [] }
}
