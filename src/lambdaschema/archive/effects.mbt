pub enum Effect {
  Async
  Throws(LambdaType)
  Pure
  IO
  State(LambdaType)
  Reader(LambdaType)
  Writer(LambdaType)
} derive(Eq)

pub enum AsyncType {
  Promise(LambdaType)
  Future(LambdaType)
  Observable(LambdaType)
  AsyncIterator(LambdaType)
} derive(Eq)

pub enum ResultType {
  Result(LambdaType, LambdaType)  // Ok type, Err type
  Either(LambdaType, LambdaType)  // Left type, Right type
  Maybe(LambdaType)                // Some type (None is implicit)
  Option(LambdaType)               // Some type
} derive(Eq)

pub struct EffectfulFunction {
  base_function : FunctionType
  effects : Array[Effect]
  error_handling : ErrorHandling?
} derive(Eq)

pub enum ErrorHandling {
  TryCatch(LambdaType)           // Exception type
  ResultReturn(LambdaType)       // Error type
  Propagate                       // Error propagation
  Panic                          // Unrecoverable error
} derive(Eq)

pub fn EffectfulFunction::async_function(
  params : Array[Parameter],
  return_type : LambdaType
) -> EffectfulFunction {
  {
    base_function: {
      name: None,
      type_parameters: Array::new(),
      parameters: params,
      return_type: LambdaType::Async(Promise(return_type)),
      throws: None
    },
    effects: [Effect::Async],
    error_handling: None
  }
}

pub fn EffectfulFunction::result_function(
  params : Array[Parameter],
  ok_type : LambdaType,
  err_type : LambdaType
) -> EffectfulFunction {
  {
    base_function: {
      name: None,
      type_parameters: Array::new(),
      parameters: params,
      return_type: LambdaType::Result(Result(ok_type, err_type)),
      throws: None
    },
    effects: [Effect::Pure],
    error_handling: Some(ResultReturn(err_type))
  }
}

pub fn EffectfulFunction::async_result_function(
  params : Array[Parameter],
  ok_type : LambdaType,
  err_type : LambdaType
) -> EffectfulFunction {
  {
    base_function: {
      name: None,
      type_parameters: Array::new(),
      parameters: params,
      return_type: LambdaType::Async(Promise(LambdaType::Result(Result(ok_type, err_type)))),
      throws: None
    },
    effects: [Effect::Async],
    error_handling: Some(ResultReturn(err_type))
  }
}

pub fn compose_effects(effects : Array[Effect]) -> Effect {
  if effects.is_empty() {
    return Effect::Pure
  }
  
  let has_async = effects.iter().any(fn(e) {
    match e {
      Effect::Async => true
      _ => false
    }
  })
  
  let has_io = effects.iter().any(fn(e) {
    match e {
      Effect::IO => true
      _ => false
    }
  })
  
  if has_async {
    Effect::Async
  } else if has_io {
    Effect::IO
  } else {
    effects[0]
  }
}

pub fn is_pure_function(func : EffectfulFunction) -> Bool {
  func.effects.iter().all(fn(e) {
    match e {
      Effect::Pure => true
      _ => false
    }
  })
}

pub fn can_compose(f1 : EffectfulFunction, f2 : EffectfulFunction) -> Bool {
  match (f1.base_function.return_type, f2.base_function.parameters.get(0)) {
    (ret_type, Some(param)) => {
      ret_type.is_subtype_of(param.param_type)
    }
    _ => false
  }
}

pub fn chain_async(
  funcs : Array[EffectfulFunction]
) -> EffectfulFunction? {
  if funcs.is_empty() {
    return None
  }
  
  let first = funcs[0]
  let last = funcs[funcs.length() - 1]
  
  Some({
    base_function: {
      name: None,
      type_parameters: Array::new(),
      parameters: first.base_function.parameters,
      return_type: last.base_function.return_type,
      throws: None
    },
    effects: [Effect::Async],
    error_handling: last.error_handling
  })
}

pub fn lift_to_async(func : FunctionType) -> EffectfulFunction {
  {
    base_function: {
      name: func.name,
      type_parameters: func.type_parameters,
      parameters: func.parameters,
      return_type: LambdaType::Async(Promise(func.return_type)),
      throws: func.throws
    },
    effects: [Effect::Async],
    error_handling: match func.throws {
      Some(err_type) => Some(TryCatch(err_type))
      None => None
    }
  }
}

pub fn lift_to_result(
  func : FunctionType,
  error_type : LambdaType
) -> EffectfulFunction {
  {
    base_function: {
      name: func.name,
      type_parameters: func.type_parameters,
      parameters: func.parameters,
      return_type: LambdaType::Result(Result(func.return_type, error_type)),
      throws: None
    },
    effects: [Effect::Pure],
    error_handling: Some(ResultReturn(error_type))
  }
}