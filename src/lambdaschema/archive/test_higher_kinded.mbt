// 高階型とジェネリクスのテスト

test "kind_inference" {
  // * -> * の種を持つ型コンストラクタ
  let array_ctor = HigherType::TypeConstructor("Array", Kind::Arrow(Kind::Type, Kind::Type))
  assert_eq(infer_kind(array_ctor), Kind::Arrow(Kind::Type, Kind::Type))
  
  // Array<String> は * の種を持つ
  let string_type = HigherType::Base(LambdaType::Schema("string"))
  let array_string = HigherType::TypeApplication(array_ctor, [string_type])
  assert_eq(infer_kind(array_string), Kind::Type)
  
  // (* -> *) -> * の種を持つ型
  let higher_ctor = HigherType::TypeConstructor(
    "Functor",
    Kind::Arrow(Kind::Arrow(Kind::Type, Kind::Type), Kind::Type)
  )
  assert_eq(
    infer_kind(higher_ctor),
    Kind::Arrow(Kind::Arrow(Kind::Type, Kind::Type), Kind::Type)
  )
}

test "type_application" {
  let maybe_ctor = HigherType::TypeConstructor("Maybe", Kind::Arrow(Kind::Type, Kind::Type))
  let string_type = HigherType::Base(LambdaType::Schema("string"))
  
  // Maybe<String> の作成
  match partial_apply(maybe_ctor, [string_type]) {
    Ok(maybe_string) => {
      assert_eq(infer_kind(maybe_string), Kind::Type)
    }
    Err(_) => assert_true(false)
  }
  
  // 過剰な引数でエラー
  match partial_apply(maybe_ctor, [string_type, string_type]) {
    Ok(_) => assert_true(false)
    Err(msg) => assert_true(msg.contains("Too many"))
  }
}

test "higher_type_subtyping" {
  let string_type = HigherType::Base(LambdaType::Schema("string"))
  let number_type = HigherType::Base(LambdaType::Schema("number"))
  let any_type = HigherType::Base(LambdaType::Any)
  
  // 基本的なサブタイピング
  assert_true(string_type.is_subtype_of(any_type))
  assert_false(any_type.is_subtype_of(string_type))
  
  // 型適用のサブタイピング
  let array_ctor = HigherType::TypeConstructor("Array", Kind::Arrow(Kind::Type, Kind::Type))
  let array_string = HigherType::TypeApplication(array_ctor, [string_type])
  let array_any = HigherType::TypeApplication(array_ctor, [any_type])
  
  assert_true(array_string.is_subtype_of(array_any))
  assert_false(array_any.is_subtype_of(array_string))
}

test "functor_type_class" {
  let functor = create_functor_class()
  assert_eq(functor.name, "Functor")
  assert_eq(functor.kind, Kind::Arrow(Kind::Type, Kind::Type))
  
  // fmap メソッドの存在確認
  assert_true(functor.methods.contains("fmap"))
  
  // 法則の確認
  assert_eq(functor.laws.length(), 2)
  assert_eq(functor.laws[0].name, "identity")
  assert_eq(functor.laws[1].name, "composition")
}

test "monad_type_class" {
  let monad = create_monad_class()
  assert_eq(monad.name, "Monad")
  
  // メソッドの確認
  assert_true(monad.methods.contains("return"))
  assert_true(monad.methods.contains("bind"))
  
  // モナド則の確認
  assert_eq(monad.laws.length(), 3)
}

test "generic_variance" {
  // 共変な型パラメータ
  let covariant_param : GenericParam = {
    name: "T",
    kind: Kind::Type,
    variance: Variance::Covariant,
    constraint: None,
    default: None
  }
  
  // 反変な型パラメータ
  let contravariant_param : GenericParam = {
    name: "T",
    kind: Kind::Type,
    variance: Variance::Contravariant,
    constraint: None,
    default: None
  }
  
  assert_eq(covariant_param.variance, Variance::Covariant)
  assert_eq(contravariant_param.variance, Variance::Contravariant)
}

test "generic_constraints" {
  let string_type = HigherType::Base(LambdaType::Schema("string"))
  let number_type = HigherType::Base(LambdaType::Schema("number"))
  
  // Extends制約
  let extends_string = GenericConstraint::Extends(string_type)
  let registry = TypeRegistry::new()
  let context = ValidationContext::new(registry)
  
  assert_true(check_generic_constraint(string_type, extends_string, context))
  assert_false(check_generic_constraint(number_type, extends_string, context))
  
  // Union制約
  let union_constraint = GenericConstraint::Union([
    GenericConstraint::Extends(string_type),
    GenericConstraint::Extends(number_type)
  ])
  
  assert_true(check_generic_constraint(string_type, union_constraint, context))
  assert_true(check_generic_constraint(number_type, union_constraint, context))
}

test "conditional_types" {
  let registry = TypeRegistry::new()
  let context = TypeInferenceContext::new(registry)
  
  let string_type = HigherType::Base(LambdaType::Schema("string"))
  let number_type = HigherType::Base(LambdaType::Schema("number"))
  let any_type = HigherType::Base(LambdaType::Any)
  
  // T extends string ? number : boolean
  let true_branch = number_type
  let false_branch = HigherType::Base(LambdaType::Schema("boolean"))
  
  // string extends string ? number : boolean => number
  let result1 = evaluate_conditional(string_type, string_type, true_branch, false_branch, context)
  assert_eq(result1, true_branch)
  
  // number extends string ? number : boolean => boolean
  let result2 = evaluate_conditional(number_type, string_type, true_branch, false_branch, context)
  assert_eq(result2, false_branch)
}

test "higher_order_function_types" {
  let registry = TypeRegistry::new()
  let context = HigherOrderContext::new(registry)
  
  // map関数の型
  let map_type = infer_map_function(context)
  match map_type {
    Forall(params, body) => {
      assert_eq(params.length(), 2)
      assert_eq(params[0].name, "a")
      assert_eq(params[1].name, "b")
    }
    _ => assert_true(false)
  }
  
  // compose関数の型
  let compose_type = infer_compose_function(context)
  match compose_type {
    Forall(params, body) => {
      assert_eq(params.length(), 3)
      assert_eq(params[0].name, "a")
      assert_eq(params[1].name, "b")
      assert_eq(params[2].name, "c")
    }
    _ => assert_true(false)
  }
}

test "curry_function_type" {
  // (String, Number) -> Boolean
  let uncurried = LambdaType::Function({
    name: Some("test"),
    type_parameters: [],
    parameters: [
      { name: "s", param_type: LambdaType::Schema("string"), optional: false, default_value: None },
      { name: "n", param_type: LambdaType::Schema("number"), optional: false, default_value: None }
    ],
    return_type: LambdaType::Schema("boolean"),
    throws: None
  })
  
  // String -> (Number -> Boolean)
  match curry_type(uncurried) {
    Ok(curried) => {
      match curried {
        Function(f) => {
          assert_eq(f.parameters.length(), 1)
          match f.parameters[0].param_type {
            Schema("string") => assert_true(true)
            _ => assert_true(false)
          }
          match f.return_type {
            Function(inner) => {
              assert_eq(inner.parameters.length(), 1)
              match inner.parameters[0].param_type {
                Schema("number") => assert_true(true)
                _ => assert_true(false)
              }
              match inner.return_type {
                Schema("boolean") => assert_true(true)
                _ => assert_true(false)
              }
            }
            _ => assert_true(false)
          }
        }
        _ => assert_true(false)
      }
    }
    Err(_) => assert_true(false)
  }
}

test "partial_application_type" {
  let registry = TypeRegistry::new()
  let context = HigherOrderContext::new(registry)
  
  // (String, Number, Boolean) -> String
  let func = LambdaType::Function({
    name: Some("test"),
    type_parameters: [],
    parameters: [
      { name: "s", param_type: LambdaType::Schema("string"), optional: false, default_value: None },
      { name: "n", param_type: LambdaType::Schema("number"), optional: false, default_value: None },
      { name: "b", param_type: LambdaType::Schema("boolean"), optional: false, default_value: None }
    ],
    return_type: LambdaType::Schema("string"),
    throws: None
  })
  
  // 1つの引数を部分適用
  let applied_args = [LambdaType::Schema("string")]
  
  match partial_apply_type(func, applied_args, context) {
    Ok(partial) => {
      match partial {
        Function(f) => {
          assert_eq(f.parameters.length(), 2)
          match f.parameters[0].param_type {
            Schema("number") => assert_true(true)
            _ => assert_true(false)
          }
          match f.parameters[1].param_type {
            Schema("boolean") => assert_true(true)
            _ => assert_true(false)
          }
        }
        _ => assert_true(false)
      }
    }
    Err(_) => assert_true(false)
  }
}