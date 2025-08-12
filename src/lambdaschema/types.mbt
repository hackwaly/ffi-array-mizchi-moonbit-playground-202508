pub typealias String as TypeName

pub struct LegacyTypeParameter {
  name : TypeName
  constraint : LegacyTypeConstraint?
}

// TypeParameterのEq実装
impl Eq for LegacyTypeParameter with op_equal(self, other) {
  self.name == other.name && self.constraint == other.constraint
}

pub enum LegacyTypeConstraint {
  LegacyExtends(LambdaType)
  LegacySuper(LambdaType)
}

// Eq実装を追加
impl Eq for LegacyTypeConstraint with op_equal(self, other) {
  match (self, other) {
    (LegacyExtends(t1), LegacyExtends(t2)) => t1 == t2
    (LegacySuper(t1), LegacySuper(t2)) => t1 == t2
    _ => false
  }
}

pub enum LambdaType {
  Named(TypeName, Array[LambdaType])
  Function(FunctionType)
  Array(LambdaType)
  Tuple(Array[LambdaType])
  Union(Array[LambdaType])
  Intersection(Array[LambdaType])
  TypeParameter(TypeName)
  Ref(String)
  Schema(String)
  // Async(AsyncType)
  // Result(ResultType)
  // Effect(Effect, LambdaType)
  Any
  Never
  Void
  Null
  Undefined
} derive(Eq)

pub struct FunctionType {
  name : String?
  type_parameters : Array[LegacyTypeParameter]
  parameters : Array[Parameter]
  return_type : LambdaType
  throws : LambdaType?
} derive(Eq)

pub struct Parameter {
  name : String
  param_type : LambdaType
  optional : Bool
  default_value : String?
} derive(Eq)

pub struct TypeRegistry {
  types : Map[String, LambdaType]
}

pub fn TypeRegistry::new() -> TypeRegistry {
  {
    types: Map::new()
  }
}

pub fn register(self : TypeRegistry, name : String, type_def : LambdaType) -> Unit {
  self.types[name] = type_def
}

pub fn resolve(self : TypeRegistry, name : String) -> LambdaType? {
  self.types.get(name)
}


pub fn LambdaType::instantiate(
  self : LambdaType,
  type_args : Map[TypeName, LambdaType]
) -> LambdaType {
  match self {
    TypeParameter(name) => type_args.get(name).unwrap_or(self)
    Named(name, args) => {
      let instantiated_args = args.map(fn(arg) { arg.instantiate(type_args) })
      Named(name, instantiated_args)
    }
    Function(func) => {
      let instantiated_params = func.parameters.map(fn(param) {
        { ..param, param_type: param.param_type.instantiate(type_args) }
      })
      let instantiated_return = func.return_type.instantiate(type_args)
      let instantiated_throws = func.throws.map(fn(t) { t.instantiate(type_args) })
      Function({
        ..func,
        parameters: instantiated_params,
        return_type: instantiated_return,
        throws: instantiated_throws
      })
    }
    Array(elem) => Array(elem.instantiate(type_args))
    Tuple(elems) => Tuple(elems.map(fn(e) { e.instantiate(type_args) }))
    Union(types) => Union(types.map(fn(t) { t.instantiate(type_args) }))
    Intersection(types) => Intersection(types.map(fn(t) { t.instantiate(type_args) }))
    // Async(async_type) => Async(async_type.instantiate(type_args))
    // Result(result_type) => Result(result_type.instantiate(type_args))
    // Effect(eff, inner) => Effect(eff, inner.instantiate(type_args))
    _ => self
  }
}

pub fn LambdaType::is_subtype_of(self : LambdaType, other : LambdaType) -> Bool {
  match (self, other) {
    (_, Any) => true
    (Never, _) => true
    (Null, Null) => true
    (Undefined, Undefined) => true
    (Void, Void) => true
    
    (TypeParameter(a), TypeParameter(b)) => a == b
    
    (Named(name1, args1), Named(name2, args2)) => {
      if name1 != name2 || args1.length() != args2.length() {
        return false
      }
      for i in 0..<args1.length() {
        if not(args1[i].is_subtype_of(args2[i])) {
          return false
        }
      }
      true
    }
    
    (Array(elem1), Array(elem2)) => elem1.is_subtype_of(elem2)
    
    (Tuple(elems1), Tuple(elems2)) => {
      if elems1.length() != elems2.length() {
        return false
      }
      for i in 0..<elems1.length() {
        if not(elems1[i].is_subtype_of(elems2[i])) {
          return false
        }
      }
      true
    }
    
    (Union(types), _) => {
      for t in types {
        if not(t.is_subtype_of(other)) {
          return false
        }
      }
      true
    }
    
    (_, Union(types)) => {
      for t in types {
        if self.is_subtype_of(t) {
          return true
        }
      }
      false
    }
    
    (Intersection(types), _) => {
      for t in types {
        if t.is_subtype_of(other) {
          return true
        }
      }
      false
    }
    
    // (Async(a1), Async(a2)) => a1.is_subtype_of(a2)
    // (Result(r1), Result(r2)) => r1.is_subtype_of(r2)
    // (Effect(e1, t1), Effect(e2, t2)) => e1 == e2 && t1.is_subtype_of(t2)
    
    (Function(f1), Function(f2)) => {
      if f1.parameters.length() != f2.parameters.length() {
        return false
      }
      
      for i in 0..<f1.parameters.length() {
        if not(f2.parameters[i].param_type.is_subtype_of(f1.parameters[i].param_type)) {
          return false
        }
      }
      
      f1.return_type.is_subtype_of(f2.return_type)
    }
    
    _ => false
  }
}

pub fn check_type_constraint(
  type_param : LambdaType,
  constraint : LegacyTypeConstraint
) -> Bool {
  match constraint {
    LegacyExtends(bound) => type_param.is_subtype_of(bound)
    LegacySuper(bound) => bound.is_subtype_of(type_param)
  }
}