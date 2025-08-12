pub fn AsyncType::instantiate(
  self : AsyncType,
  type_args : Map[TypeName, LambdaType]
) -> AsyncType {
  match self {
    Promise(inner) => Promise(inner.instantiate(type_args))
    Future(inner) => Future(inner.instantiate(type_args))
    Observable(inner) => Observable(inner.instantiate(type_args))
    AsyncIterator(inner) => AsyncIterator(inner.instantiate(type_args))
  }
}

pub fn ResultType::instantiate(
  self : ResultType,
  type_args : Map[TypeName, LambdaType]
) -> ResultType {
  match self {
    Result(ok, err) => Result(ok.instantiate(type_args), err.instantiate(type_args))
    Either(left, right) => Either(left.instantiate(type_args), right.instantiate(type_args))
    Maybe(inner) => Maybe(inner.instantiate(type_args))
    Option(inner) => Option(inner.instantiate(type_args))
  }
}

pub fn AsyncType::is_subtype_of(self : AsyncType, other : AsyncType) -> Bool {
  match (self, other) {
    (Promise(a), Promise(b)) => a.is_subtype_of(b)
    (Future(a), Future(b)) => a.is_subtype_of(b)
    (Observable(a), Observable(b)) => a.is_subtype_of(b)
    (AsyncIterator(a), AsyncIterator(b)) => a.is_subtype_of(b)
    _ => false
  }
}

pub fn ResultType::is_subtype_of(self : ResultType, other : ResultType) -> Bool {
  match (self, other) {
    (Result(ok1, err1), Result(ok2, err2)) => ok1.is_subtype_of(ok2) && err2.is_subtype_of(err1)
    (Either(l1, r1), Either(l2, r2)) => l1.is_subtype_of(l2) && r1.is_subtype_of(r2)
    (Maybe(a), Maybe(b)) => a.is_subtype_of(b)
    (Option(a), Option(b)) => a.is_subtype_of(b)
    (Maybe(a), Option(b)) => a.is_subtype_of(b)
    (Option(a), Maybe(b)) => a.is_subtype_of(b)
    _ => false
  }
}

pub fn AsyncType::map(self : AsyncType, f : (LambdaType) -> LambdaType) -> AsyncType {
  match self {
    Promise(inner) => Promise(f(inner))
    Future(inner) => Future(f(inner))
    Observable(inner) => Observable(f(inner))
    AsyncIterator(inner) => AsyncIterator(f(inner))
  }
}

pub fn ResultType::map_ok(self : ResultType, f : (LambdaType) -> LambdaType) -> ResultType {
  match self {
    Result(ok, err) => Result(f(ok), err)
    Either(left, right) => Either(left, f(right))
    Maybe(inner) => Maybe(f(inner))
    Option(inner) => Option(f(inner))
  }
}

pub fn ResultType::map_err(self : ResultType, f : (LambdaType) -> LambdaType) -> ResultType {
  match self {
    Result(ok, err) => Result(ok, f(err))
    Either(left, right) => Either(f(left), right)
    _ => self
  }
}

pub fn AsyncType::flatten(self : AsyncType) -> LambdaType {
  match self {
    Promise(inner) => inner
    Future(inner) => inner
    Observable(inner) => inner
    AsyncIterator(inner) => inner
  }
}

pub fn ResultType::unwrap_ok(self : ResultType) -> LambdaType {
  match self {
    Result(ok, _) => ok
    Either(_, right) => right
    Maybe(inner) => inner
    Option(inner) => inner
  }
}

pub fn ResultType::unwrap_err(self : ResultType) -> LambdaType? {
  match self {
    Result(_, err) => Some(err)
    Either(left, _) => Some(left)
    _ => None
  }
}