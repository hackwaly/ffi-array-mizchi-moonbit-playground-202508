pub struct FunctionBuilder {
  mut name : String?
  mut type_parameters : Array[TypeParameter]
  mut parameters : Array[Parameter]
  mut return_type : LambdaType
  mut throws : LambdaType?
}

pub fn FunctionBuilder::new() -> FunctionBuilder {
  {
    name: None,
    type_parameters: Array::new(),
    parameters: Array::new(),
    return_type: Void,
    throws: None
  }
}

pub fn with_name(self : FunctionBuilder, name : String) -> FunctionBuilder {
  self.name = Some(name)
  self
}

pub fn with_type_parameter(
  self : FunctionBuilder,
  name : String,
  constraint : TypeConstraint?
) -> FunctionBuilder {
  self.type_parameters.push({ name, constraint })
  self
}

pub fn with_parameter(
  self : FunctionBuilder,
  name : String,
  param_type : LambdaType,
  optional : Bool,
  default_value : String?
) -> FunctionBuilder {
  self.parameters.push({ name, param_type, optional, default_value })
  self
}

pub fn with_return_type(self : FunctionBuilder, return_type : LambdaType) -> FunctionBuilder {
  self.return_type = return_type
  self
}

pub fn with_throws(self : FunctionBuilder, throws : LambdaType) -> FunctionBuilder {
  self.throws = Some(throws)
  self
}

pub fn build(self : FunctionBuilder) -> FunctionType {
  {
    name: self.name,
    type_parameters: self.type_parameters,
    parameters: self.parameters,
    return_type: self.return_type,
    throws: self.throws
  }
}

pub fn LambdaType::string() -> LambdaType {
  Schema("string")
}

pub fn LambdaType::number() -> LambdaType {
  Schema("number")
}

pub fn LambdaType::boolean() -> LambdaType {
  Schema("boolean")
}

pub fn LambdaType::array(element_type : LambdaType) -> LambdaType {
  Array(element_type)
}

pub fn LambdaType::tuple(element_types : Array[LambdaType]) -> LambdaType {
  Tuple(element_types)
}

pub fn LambdaType::union(types : Array[LambdaType]) -> LambdaType {
  Union(types)
}

pub fn LambdaType::intersection(types : Array[LambdaType]) -> LambdaType {
  Intersection(types)
}

pub fn LambdaType::function(
  params : Array[Parameter],
  return_type : LambdaType
) -> LambdaType {
  Function({
    name: None,
    type_parameters: Array::new(),
    parameters: params,
    return_type,
    throws: None
  })
}

pub fn LambdaType::generic_function(
  type_params : Array[TypeParameter],
  params : Array[Parameter],
  return_type : LambdaType
) -> LambdaType {
  Function({
    name: None,
    type_parameters: type_params,
    parameters: params,
    return_type,
    throws: None
  })
}