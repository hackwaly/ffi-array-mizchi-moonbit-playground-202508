// Top-level AST node
pub struct Program {
  statements : Array[Statement]
} derive(Show)

// Block statement (for function bodies, if-then-else, etc.)
pub struct Block {
  statements : Array[Statement]
} derive(Show)

// Statement can be a declaration or an expression
pub enum Statement {
  Declaration(Declaration)
  Expression(Expression)
  Block(Block)
  Return(Expression?)
  If(Expression, Statement, Statement?)
  While(Expression, Statement)
  For(ForStatement)
  Break
  Continue
  Throw(Expression)
  Try(Block, CatchClause?, Block?)
} derive(Show)

pub struct ForStatement {
  init : Statement?
  condition : Expression?
  update : Expression?
  body : Statement
} derive(Show)

pub struct CatchClause {
  param : String?
  body : Block
} derive(Show)

// Expression types
pub enum Expression {
  Identifier(String)
  Literal(LiteralType)
  Binary(BinaryOp, Expression, Expression)
  Unary(UnaryOp, Expression)
  Assignment(String, Expression)
  Call(Expression, Array[Expression])
  Member(Expression, String)
  Conditional(Expression, Expression, Expression)
  Array(Array[Expression])
  Object(Map[String, Expression])
  Function(FunctionExpression)
  Arrow(ArrowFunction)
  TypeAssertion(Expression, Type)
} derive(Show)

pub enum BinaryOp {
  Add
  Subtract
  Multiply
  Divide
  Modulo
  Equal
  NotEqual
  StrictEqual
  StrictNotEqual
  LessThan
  LessThanOrEqual
  GreaterThan
  GreaterThanOrEqual
  LogicalAnd
  LogicalOr
  BitwiseAnd
  BitwiseOr
  BitwiseXor
  LeftShift
  RightShift
  UnsignedRightShift
} derive(Show)

pub enum UnaryOp {
  Plus
  Minus
  Not
  BitwiseNot
  TypeOf
  Void
  Delete
} derive(Show)

pub struct FunctionExpression {
  name : String?
  params : Array[Parameter]
  return_type : Type?
  body : Block
  is_async : Bool
} derive(Show)

pub struct ArrowFunction {
  params : Array[Parameter]
  return_type : Type?
  body : Statement  // Can be Block or Expression
  is_async : Bool
} derive(Show)

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
  Enum(EnumDeclaration)
  Export(ExportDeclaration)
  Import(ImportDeclaration)
} derive(Show)

pub struct InterfaceDeclaration {
  name : String
  type_params : Array[String]
  extends : Array[String]
  members : Array[InterfaceMember]
} derive(Show)

pub enum InterfaceMember {
  Property(PropertyMember)
  Method(MethodMember)
  Constructor(ConstructorMember)
  IndexSignature(IndexSignatureMember)
} derive(Show)

pub struct PropertyMember {
  name : String
  type_ : Type
  optional : Bool
  readonly_ : Bool
} derive(Show)

pub struct MethodMember {
  name : String
  params : Array[Parameter]
  return_type : Type
  optional : Bool
} derive(Show)

pub struct ConstructorMember {
  params : Array[Parameter]
} derive(Show)

pub struct IndexSignatureMember {
  key_name : String
  key_type : Type
  value_type : Type
  readonly_ : Bool
} derive(Show)

pub struct TypeAliasDeclaration {
  name : String
  type_params : Array[String]
  type_ : Type
} derive(Show)

pub struct FunctionDeclaration {
  name : String
  params : Array[Parameter]
  return_type : Type
  declare : Bool
  is_async : Bool
} derive(Show)

pub struct ClassDeclaration {
  name : String
  type_params : Array[String]
  extends : Option[String]
  implements : Array[String]
  members : Array[ClassMember]
  declare : Bool
} derive(Show)

pub enum ClassMember {
  ClassProperty(ClassPropertyMember)
  ClassMethod(ClassMethodMember)
  ClassConstructor(ClassConstructorMember)
} derive(Show)

pub struct ClassPropertyMember {
  name : String
  type_ : Type
  visibility : Visibility
  is_static : Bool
  readonly_ : Bool
  optional : Bool
} derive(Show)

pub struct ClassMethodMember {
  name : String
  params : Array[Parameter]
  return_type : Type
  visibility : Visibility
  is_static : Bool
} derive(Show)

pub struct ClassConstructorMember {
  params : Array[Parameter]
  visibility : Visibility
} derive(Show)

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
} derive(Show)

pub enum VariableKind {
  Const
  Let
  Var
} derive(Show)

pub struct ModuleDeclaration {
  name : String
  declarations : Array[Declaration]
  declare : Bool
} derive(Show)

pub struct NamespaceDeclaration {
  name : String
  declarations : Array[Declaration]
  declare : Bool
} derive(Show)

pub struct EnumDeclaration {
  name : String
  is_const : Bool
  members : Array[EnumMember]
} derive(Show)

pub struct EnumMember {
  name : String
  value : Option[String]
} derive(Show)

pub struct ExportDeclaration {
  declaration : Option[Declaration]
  named_exports : Array[ExportSpecifier]
  from : Option[String]
} derive(Show)

pub struct ExportSpecifier {
  local_name : String
  exported : Option[String]
} derive(Show)

pub struct ImportDeclaration {
  specifiers : Array[ImportSpecifier]
  from : String
  is_type_only : Bool
} derive(Show)

pub enum ImportSpecifier {
  Named(String, Option[String])
  Default(String)
  Namespace(String)
} derive(Show)

pub struct DtsFile {
  declarations : Array[Declaration]
} derive(Show)