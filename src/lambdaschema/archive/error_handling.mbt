pub struct SafeFunction {
  base : FunctionType
  error_strategy : ErrorStrategy
  recovery : RecoveryStrategy?
} derive(Eq)

pub enum ErrorStrategy {
  TryCatch(Array[ErrorHandler])
  ResultMonad
  MaybeMonad
  Panic
  Ignore
} derive(Eq)

pub struct ErrorHandler {
  error_type : LambdaType
  handler : FunctionType
} derive(Eq)

pub enum RecoveryStrategy {
  Retry(Int, Int)  // max_attempts, delay_ms
  Fallback(LambdaType)  // default_value
  Circuit(Int, Int)  // threshold, timeout_ms
  Transform(FunctionType)  // transformer
} derive(Eq)

pub fn SafeFunction::from_unsafe(
  func : FunctionType,
  potential_errors : Array[LambdaType]
) -> SafeFunction {
  let error_union = if potential_errors.length() == 1 {
    potential_errors[0]
  } else {
    LambdaType::Union(potential_errors)
  }
  
  {
    base: {
      name: func.name,
      type_parameters: func.type_parameters,
      parameters: func.parameters,
      return_type: LambdaType::Result(Result(func.return_type, error_union)),
      throws: None
    },
    error_strategy: ErrorStrategy::ResultMonad,
    recovery: None
  }
}

pub fn SafeFunction::with_try_catch(
  func : FunctionType,
  handlers : Array[ErrorHandler]
) -> SafeFunction {
  {
    base: func,
    error_strategy: ErrorStrategy::TryCatch(handlers),
    recovery: None
  }
}

pub fn SafeFunction::with_fallback(
  self : SafeFunction,
  default_value : LambdaType
) -> SafeFunction {
  {
    ..self,
    recovery: Some(RecoveryStrategy::Fallback(default_value))
  }
}

pub fn SafeFunction::with_retry(
  self : SafeFunction,
  max_attempts : Int,
  delay_ms : Int
) -> SafeFunction {
  {
    ..self,
    recovery: Some(RecoveryStrategy::Retry(max_attempts, delay_ms))
  }
}

pub fn ErrorHandler::new(
  error_type : LambdaType,
  handler : FunctionType
) -> ErrorHandler {
  {
    error_type,
    handler
  }
}

pub fn compose_safe_functions(
  f1 : SafeFunction,
  f2 : SafeFunction
) -> SafeFunction? {
  match (f1.base.return_type, f2.base.parameters.get(0)) {
    (LambdaType::Result(Result(ok1, _)), Some(param)) if ok1.is_subtype_of(param.param_type) => {
      let combined_errors = match (f1.base.return_type, f2.base.return_type) {
        (LambdaType::Result(Result(_, err1)), LambdaType::Result(Result(_, err2))) => {
          LambdaType::Union([err1, err2])
        }
        _ => LambdaType::Never
      }
      
      Some({
        base: {
          name: None,
          type_parameters: Array::new(),
          parameters: f1.base.parameters,
          return_type: LambdaType::Result(Result(
            match f2.base.return_type {
              LambdaType::Result(Result(ok, _)) => ok
              other => other
            },
            combined_errors
          )),
          throws: None
        },
        error_strategy: f2.error_strategy,
        recovery: f2.recovery
      })
    }
    _ => None
  }
}

pub fn validate_error_handling(func : SafeFunction) -> Array[String] {
  let issues : Array[String] = Array::new()
  
  match func.error_strategy {
    ErrorStrategy::TryCatch(handlers) => {
      if handlers.is_empty() {
        issues.push("TryCatch strategy requires at least one error handler")
      }
      
      for handler in handlers {
        match handler.handler.parameters.get(0) {
          Some(param) if not(handler.error_type.is_subtype_of(param.param_type)) => {
            issues.push("Error handler parameter type doesn't match error type")
          }
          None => issues.push("Error handler must have at least one parameter")
          _ => ()
        }
      }
    }
    ErrorStrategy::Ignore => {
      issues.push("Warning: Ignore strategy may lead to unhandled errors")
    }
    _ => ()
  }
  
  match func.recovery {
    Some(RecoveryStrategy::Retry(max, _)) if max <= 0 => {
      issues.push("Retry strategy requires positive max_attempts")
    }
    Some(RecoveryStrategy::Circuit(threshold, _)) if threshold <= 0 => {
      issues.push("Circuit breaker requires positive threshold")
    }
    _ => ()
  }
  
  issues
}

pub fn create_error_boundary(
  funcs : Array[SafeFunction],
  global_handler : ErrorHandler
) -> SafeFunction {
  let all_params : Array[Parameter] = Array::new()
  let all_returns : Array[LambdaType] = Array::new()
  
  for func in funcs {
    for param in func.base.parameters {
      if not(all_params.iter().any(fn(p) { p.name == param.name })) {
        all_params.push(param)
      }
    }
    all_returns.push(func.base.return_type)
  }
  
  {
    base: {
      name: None,
      type_parameters: Array::new(),
      parameters: all_params,
      return_type: LambdaType::Tuple(all_returns),
      throws: None
    },
    error_strategy: ErrorStrategy::TryCatch([global_handler]),
    recovery: None
  }
}

pub fn transform_to_maybe(func : SafeFunction) -> SafeFunction {
  let new_return = match func.base.return_type {
    LambdaType::Result(Result(ok, _)) => LambdaType::Result(Maybe(ok))
    other => LambdaType::Result(Maybe(other))
  }
  
  {
    base: {
      ..func.base,
      return_type: new_return
    },
    error_strategy: ErrorStrategy::MaybeMonad,
    recovery: func.recovery
  }
}

pub fn chain_with_error_propagation(
  funcs : Array[SafeFunction]
) -> SafeFunction? {
  if funcs.is_empty() {
    return None
  }
  
  let first = funcs[0]
  let mut current = first
  
  for i in 1..<funcs.length() {
    match compose_safe_functions(current, funcs[i]) {
      Some(composed) => current = composed
      None => return None
    }
  }
  
  Some(current)
}