pub struct AsyncPattern {
  pattern_type : AsyncPatternType
  input_type : LambdaType
  output_type : LambdaType
  error_type : LambdaType?
} derive(Eq)

pub enum AsyncPatternType {
  AsyncAwait
  Promise
  Callback
  EventEmitter
  Stream
  Generator
} derive(Eq)

pub fn AsyncPattern::async_await(
  input : LambdaType,
  output : LambdaType,
  error : LambdaType?
) -> AsyncPattern {
  {
    pattern_type: AsyncPatternType::AsyncAwait,
    input_type: input,
    output_type: output,
    error_type: error
  }
}

pub fn AsyncPattern::promise_chain(
  input : LambdaType,
  output : LambdaType
) -> AsyncPattern {
  {
    pattern_type: AsyncPatternType::Promise,
    input_type: input,
    output_type: output,
    error_type: None
  }
}

pub fn AsyncPattern::callback_style(
  input : LambdaType,
  output : LambdaType,
  error : LambdaType
) -> AsyncPattern {
  {
    pattern_type: AsyncPatternType::Callback,
    input_type: input,
    output_type: output,
    error_type: Some(error)
  }
}

pub fn create_async_function(
  pattern : AsyncPattern,
  params : Array[Parameter]
) -> FunctionType {
  let return_type = match pattern.pattern_type {
    AsyncPatternType::AsyncAwait => {
      match pattern.error_type {
        Some(err) => LambdaType::Async(Promise(LambdaType::Result(Result(pattern.output_type, err))))
        None => LambdaType::Async(Promise(pattern.output_type))
      }
    }
    AsyncPatternType::Promise => LambdaType::Async(Promise(pattern.output_type))
    AsyncPatternType::Callback => {
      let callback_type = LambdaType::Function({
        name: None,
        type_parameters: Array::new(),
        parameters: match pattern.error_type {
          Some(err) => [
            { name: "error", param_type: err, optional: true, default_value: None },
            { name: "result", param_type: pattern.output_type, optional: false, default_value: None }
          ]
          None => [
            { name: "result", param_type: pattern.output_type, optional: false, default_value: None }
          ]
        },
        return_type: LambdaType::Void,
        throws: None
      })
      LambdaType::Void
    }
    _ => pattern.output_type
  }
  
  {
    name: None,
    type_parameters: Array::new(),
    parameters: params,
    return_type,
    throws: pattern.error_type
  }
}

pub fn compose_async_functions(
  f1 : FunctionType,
  f2 : FunctionType
) -> FunctionType? {
  match (f1.return_type, f2.parameters.get(0)) {
    (LambdaType::Async(Promise(t1)), Some(param)) if t1.is_subtype_of(param.param_type) => {
      Some({
        name: None,
        type_parameters: Array::new(),
        parameters: f1.parameters,
        return_type: f2.return_type,
        throws: match (f1.throws, f2.throws) {
          (Some(e1), Some(e2)) => Some(LambdaType::Union([e1, e2]))
          (Some(e), None) | (None, Some(e)) => Some(e)
          _ => None
        }
      })
    }
    _ => None
  }
}

pub fn async_pipe(
  funcs : Array[FunctionType]
) -> FunctionType? {
  if funcs.is_empty() {
    return None
  }
  
  let first = funcs[0]
  let mut current_return = first.return_type
  let mut all_errors : Array[LambdaType] = Array::new()
  
  if first.throws.is_some() {
    all_errors.push(first.throws.unwrap())
  }
  
  for i in 1..<funcs.length() {
    let func = funcs[i]
    match func.parameters.get(0) {
      Some(param) if current_return.is_subtype_of(param.param_type) => {
        current_return = func.return_type
        if func.throws.is_some() {
          all_errors.push(func.throws.unwrap())
        }
      }
      _ => return None
    }
  }
  
  Some({
    name: None,
    type_parameters: Array::new(),
    parameters: first.parameters,
    return_type: current_return,
    throws: if all_errors.is_empty() {
      None
    } else if all_errors.length() == 1 {
      Some(all_errors[0])
    } else {
      Some(LambdaType::Union(all_errors))
    }
  })
}

pub fn retry_with_backoff(
  func : FunctionType,
  max_retries : Int,
  backoff_ms : Int
) -> FunctionType {
  {
    name: func.name,
    type_parameters: func.type_parameters,
    parameters: func.parameters,
    return_type: match func.return_type {
      LambdaType::Async(async_type) => LambdaType::Async(async_type)
      other => LambdaType::Async(Promise(other))
    },
    throws: func.throws
  }
}

pub fn timeout_wrapper(
  func : FunctionType,
  timeout_ms : Int
) -> FunctionType {
  let timeout_error = LambdaType::Schema("TimeoutError")
  
  {
    name: func.name,
    type_parameters: func.type_parameters,
    parameters: func.parameters,
    return_type: match func.return_type {
      LambdaType::Async(Promise(inner)) => {
        LambdaType::Async(Promise(LambdaType::Result(Result(inner, timeout_error))))
      }
      other => LambdaType::Async(Promise(LambdaType::Result(Result(other, timeout_error))))
    },
    throws: None
  }
}

pub fn parallel_execution(
  funcs : Array[FunctionType]
) -> FunctionType? {
  if funcs.is_empty() {
    return None
  }
  
  let return_types = funcs.map(fn(f) { f.return_type })
  let all_params : Array[Parameter] = Array::new()
  
  for func in funcs {
    for param in func.parameters {
      if not(all_params.iter().any(fn(p) { p.name == param.name })) {
        all_params.push(param)
      }
    }
  }
  
  Some({
    name: None,
    type_parameters: Array::new(),
    parameters: all_params,
    return_type: LambdaType::Async(Promise(LambdaType::Tuple(return_types))),
    throws: None
  })
}