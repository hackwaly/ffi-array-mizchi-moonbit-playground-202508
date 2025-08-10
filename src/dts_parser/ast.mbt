pub enum Type {
  String
  Number
  Boolean
  Void
  Any
  Unknown
  Never
  Null
  Undefined
  Object(Map[String, Type])
  Array(Type)
  Tuple(Array[Type])
  Union(Array[Type])
  Intersection(Array[Type])
  Literal(LiteralType)
  TypeReference(String, Array[Type])
  Function(FunctionType)
  Optional(Type)
  Readonly(Type)
} derive(Show)

pub enum LiteralType {
  String(String)
  Number(String)
  Boolean(Bool)
} derive(Show)

pub struct FunctionType {
  params : Array[Parameter]
  return_type : Type
} derive(Show)

pub struct Parameter {
  name : String
  type_ : Type
  optional : Bool
  rest : Bool
} derive(Show)

pub enum Declaration {
  Interface(InterfaceDeclaration)
  TypeAlias(TypeAliasDeclaration)
  Function(FunctionDeclaration)
  Variable(VariableDeclaration)
  Class(ClassDeclaration)
  Module(ModuleDeclaration)
  Namespace(NamespaceDeclaration)
  Export(ExportDeclaration)
  Import(ImportDeclaration)
}

pub struct InterfaceDeclaration {
  name : String
  type_params : Array[String]
  extends : Array[String]
  members : Array[InterfaceMember]
}

pub enum InterfaceMember {
  Property(PropertyMember)
  Method(MethodMember)
  Constructor(ConstructorMember)
  IndexSignature(IndexSignatureMember)
}

pub struct PropertyMember {
  name : String
  type_ : Type
  optional : Bool
  readonly_ : Bool
}

pub struct MethodMember {
  name : String
  params : Array[Parameter]
  return_type : Type
  optional : Bool
}

pub struct ConstructorMember {
  params : Array[Parameter]
}

pub struct IndexSignatureMember {
  key_name : String
  key_type : Type
  value_type : Type
  readonly_ : Bool
}

pub struct TypeAliasDeclaration {
  name : String
  type_params : Array[String]
  type_ : Type
}

pub struct FunctionDeclaration {
  name : String
  params : Array[Parameter]
  return_type : Type
  declare : Bool
}

pub struct ClassDeclaration {
  name : String
  type_params : Array[String]
  extends : Option[String]
  implements : Array[String]
  members : Array[ClassMember]
  declare : Bool
}

pub enum ClassMember {
  ClassProperty(ClassPropertyMember)
  ClassMethod(ClassMethodMember)
  ClassConstructor(ClassConstructorMember)
}

pub struct ClassPropertyMember {
  name : String
  type_ : Type
  visibility : Visibility
  is_static : Bool
  readonly_ : Bool
  optional : Bool
}

pub struct ClassMethodMember {
  name : String
  params : Array[Parameter]
  return_type : Type
  visibility : Visibility
  is_static : Bool
}

pub struct ClassConstructorMember {
  params : Array[Parameter]
  visibility : Visibility
}

pub enum Visibility {
  Public
  Private
  Protected
} derive(Eq, Show)

pub struct VariableDeclaration {
  name : String
  type_ : Type
  kind : VariableKind
  declare : Bool
}

pub enum VariableKind {
  Const
  Let
  Var
}

pub struct ModuleDeclaration {
  name : String
  declarations : Array[Declaration]
  declare : Bool
}

pub struct NamespaceDeclaration {
  name : String
  declarations : Array[Declaration]
  declare : Bool
}

pub struct ExportDeclaration {
  declaration : Option[Declaration]
  named_exports : Array[ExportSpecifier]
  from : Option[String]
}

pub struct ExportSpecifier {
  local_name : String
  exported : Option[String]
}

pub struct ImportDeclaration {
  specifiers : Array[ImportSpecifier]
  from : String
}

pub enum ImportSpecifier {
  Named(String, Option[String])
  Default(String)
  Namespace(String)
}

pub struct DtsFile {
  declarations : Array[Declaration]
}