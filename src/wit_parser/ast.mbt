// WIT (WebAssembly Interface Types) AST definitions

// Top-level WIT document
pub struct WitDocument {
  package_name : Option[String]
  items : Array[TopLevelItem]
} derive(Debug, Show, Eq)

// Top-level items in a WIT document
pub enum TopLevelItem {
  Interface(Interface)
  World(World)
  Use(UseItem)
} derive(Debug, Show, Eq)

// Interface definition
pub struct Interface {
  name : String
  items : Array[InterfaceItem]
} derive(Debug, Show, Eq)

// Items within an interface
pub enum InterfaceItem {
  Use(UseItem)
  Type(TypeDef)
  Function(Function)
  Export(String)  // Export another interface
} derive(Debug, Show, Eq)

// World definition
pub struct World {
  name : String
  items : Array[WorldItem]
} derive(Debug, Show, Eq)

// Items within a world
pub enum WorldItem {
  Use(UseItem)
  Type(TypeDef)
  Import(Import)
  Export(Export)
} derive(Debug, Show, Eq)

// Import declaration
pub struct Import {
  name : String
  kind : ImportKind
} derive(Debug, Show, Eq)

pub enum ImportKind {
  Function(Function)
  Interface(String)  // Interface name
} derive(Debug, Show, Eq)

// Export declaration
pub struct Export {
  name : String
  kind : ExportKind
} derive(Debug, Show, Eq)

pub enum ExportKind {
  Function(Function)
  Interface(String)  // Interface name
} derive(Debug, Show, Eq)

// Use statement
pub struct UseItem {
  path : String  // e.g., "wasi:io/streams"
  items : Array[UseItemSpec]
} derive(Debug, Show, Eq)

pub enum UseItemSpec {
  All  // use *
  Named(Array[String])  // use { a, b, c }
} derive(Debug, Show, Eq)

// Type definition
pub struct TypeDef {
  name : String
  def : TypeDefKind
} derive(Debug, Show, Eq)

pub enum TypeDefKind {
  Alias(Type)
  Record(Record)
  Enum(Enum)
  Flags(Flags)
  Variant(Variant)
  Resource(Resource)
} derive(Debug, Show, Eq)

// Record type
pub struct Record {
  fields : Array[Field]
} derive(Debug, Show, Eq)

pub struct Field {
  name : String
  typ : Type
} derive(Debug, Show, Eq)

// Enum type
pub struct Enum {
  cases : Array[String]
} derive(Debug, Show, Eq)

// Flags type
pub struct Flags {
  flags : Array[String]
} derive(Debug, Show, Eq)

// Variant type
pub struct Variant {
  cases : Array[VariantCase]
} derive(Debug, Show, Eq)

pub struct VariantCase {
  name : String
  typ : Option[Type]
} derive(Debug, Show, Eq)

// Resource type
pub struct Resource {
  methods : Array[ResourceMethod]
} derive(Debug, Show, Eq)

pub struct ResourceMethod {
  name : String
  kind : MethodKind
} derive(Debug, Show, Eq)

pub enum MethodKind {
  Constructor(Array[Param])
  Method(Function)
  Static(Function)
} derive(Debug, Show, Eq)

// Function definition
pub struct Function {
  name : String
  params : Array[Param]
  results : FunctionResult
} derive(Debug, Show, Eq)

pub struct Param {
  name : String
  typ : Type
} derive(Debug, Show, Eq)

pub enum FunctionResult {
  None
  Single(Type)
  Named(Array[Param])
} derive(Debug, Show, Eq)

// Types
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
  Result { ok : Option[Type]; err : Option[Type] }
  Tuple(Array[Type])
  
  // Named type reference
  Named(String)
  
  // Borrow (for resource types)
  Borrow(String)
  
  // Own (for owned resource types)
  Own(String)
} derive(Debug, Show, Eq)

// Helper constructors
pub fn WitDocument::new() -> WitDocument {
  { package_name: None, items: [] }
}

pub fn WitDocument::with_package(name : String) -> WitDocument {
  { package_name: Some(name), items: [] }
}

pub fn Interface::new(name : String) -> Interface {
  { name, items: [] }
}

pub fn World::new(name : String) -> World {
  { name, items: [] }
}

pub fn Function::new(name : String) -> Function {
  { name, params: [], results: FunctionResult::None }
}

pub fn Record::new() -> Record {
  { fields: [] }
}

pub fn Enum::new() -> Enum {
  { cases: [] }
}

pub fn Flags::new() -> Flags {
  { flags: [] }
}

pub fn Variant::new() -> Variant {
  { cases: [] }
}

pub fn Resource::new() -> Resource {
  { methods: [] }
}