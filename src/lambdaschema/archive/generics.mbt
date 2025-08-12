// 高度なジェネリクス機能

// 型の変性（Variance）
pub enum Variance {
  Covariant      // 共変（+）
  Contravariant  // 反変（-）
  Invariant      // 不変（±）
  Bivariant      // 双変（無制約）
} derive(Eq)

// 拡張された型パラメータ
pub struct GenericParam {
  name : String
  kind : Kind
  variance : Variance
  constraint : GenericConstraint?
  default : HigherType?
} derive(Eq)

// より表現力豊かな制約
pub enum GenericConstraint {
  Extends(HigherType)
  Super(HigherType)
  Implements(String)  // 型クラス制約
  Union(Array[GenericConstraint])
  Intersection(Array[GenericConstraint])
} derive(Eq)

// 型レベル計算
pub enum TypeLevelComputation {
  // 条件型（Conditional Types）
  Conditional(HigherType, HigherType, HigherType, HigherType)  // T extends U ? X : Y
  
  // 型の抽出（infer）
  Infer(String, HigherType)  // infer R in Promise<R>
  
  // マップ型（Mapped Types）
  Mapped(String, HigherType, HigherType)  // { [K in T]: U }
  
  // テンプレートリテラル型
  Template(Array[TemplateElement])
} derive(Eq)

pub enum TemplateElement {
  Literal(String)
  Interpolation(HigherType)
} derive(Eq)

// 高階型の単一化
pub fn unify_higher(
  t1 : HigherType,
  t2 : HigherType,
  context : TypeInferenceContext
) -> Result[Map[String, HigherType], String] {
  let subst = Map::new()
  if unify_higher_impl(t1, t2, subst, context) {
    Ok(subst)
  } else {
    Err("Cannot unify higher types")
  }
}

fn unify_higher_impl(
  t1 : HigherType,
  t2 : HigherType,
  subst : Map[String, HigherType],
  context : TypeInferenceContext
) -> Bool {
  let t1_subst = apply_higher_substitution(t1, subst)
  let t2_subst = apply_higher_substitution(t2, subst)
  
  match (t1_subst, t2_subst) {
    // 基本型の単一化
    (Base(lt1), Base(lt2)) => {
      // 既存のLambdaType単一化を使用
      true // 簡略化
    }
    
    // 型パラメータ
    (HigherTypeParam(name1, kind1), t2) => {
      if occurs_check_higher(name1, t2) {
        false
      } else if check_kind(t2, kind1) {
        subst[name1] = t2
        true
      } else {
        false
      }
    }
    
    (t1, HigherTypeParam(name2, kind2)) => {
      if occurs_check_higher(name2, t1) {
        false
      } else if check_kind(t1, kind2) {
        subst[name2] = t1
        true
      } else {
        false
      }
    }
    
    // 型適用の単一化
    (TypeApplication(f1, args1), TypeApplication(f2, args2)) => {
      if args1.length() != args2.length() {
        return false
      }
      
      if not(unify_higher_impl(f1, f2, subst, context)) {
        return false
      }
      
      for i in 0..<args1.length() {
        if not(unify_higher_impl(args1[i], args2[i], subst, context)) {
          return false
        }
      }
      true
    }
    
    // 全称量化型
    (Forall(params1, body1), Forall(params2, body2)) => {
      if params1.length() != params2.length() {
        return false
      }
      
      // α変換を行って新しい型変数を作成
      let fresh_params = params1.map(fn(p) {
        let fresh_name = context.fresh_type_var("T").to_string()
        { name: fresh_name, kind: p.kind, constraint: p.constraint }
      })
      
      // 本体を新しい変数で置き換え
      let body1_renamed = rename_type_params(body1, params1, fresh_params)
      let body2_renamed = rename_type_params(body2, params2, fresh_params)
      
      unify_higher_impl(body1_renamed, body2_renamed, subst, context)
    }
    
    _ => false
  }
}

// 制約付きジェネリクスの検証
pub fn validate_generic_constraints(
  type_args : Map[String, HigherType],
  params : Array[GenericParam],
  context : ValidationContext
) -> Bool {
  let mut all_valid = true
  
  for param in params {
    match type_args.get(param.name) {
      Some(arg_type) => {
        // 種のチェック
        if not(check_kind(arg_type, param.kind)) {
          context.add_error(
            LambdaType::TypeParameter(param.name),
            "kind mismatch",
            "Expected kind " + kind_to_string(param.kind)
          )
          all_valid = false
        }
        
        // 制約のチェック
        match param.constraint {
          Some(constraint) => {
            if not(check_generic_constraint(arg_type, constraint, context)) {
              all_valid = false
            }
          }
          None => ()
        }
        
        // 変性のチェック
        if not(check_variance(arg_type, param.variance)) {
          context.add_error(
            LambdaType::TypeParameter(param.name),
            "variance mismatch",
            "Variance violation"
          )
          all_valid = false
        }
      }
      None => {
        // デフォルト値があれば使用
        match param.default {
          Some(default_type) => {
            type_args[param.name] = default_type
          }
          None => {
            context.add_error(
              LambdaType::TypeParameter(param.name),
              "missing",
              "Type parameter not provided"
            )
            all_valid = false
          }
        }
      }
    }
  }
  
  all_valid
}

fn check_generic_constraint(
  t : HigherType,
  constraint : GenericConstraint,
  context : ValidationContext
) -> Bool {
  match constraint {
    Extends(bound) => t.is_subtype_of(bound)
    Super(bound) => bound.is_subtype_of(t)
    Implements(type_class) => {
      // 型クラスの実装チェック（簡略化）
      true
    }
    Union(constraints) => {
      // いずれかの制約を満たす
      constraints.any(fn(c) { check_generic_constraint(t, c, context) })
    }
    Intersection(constraints) => {
      // 全ての制約を満たす
      constraints.all(fn(c) { check_generic_constraint(t, c, context) })
    }
  }
}

fn check_variance(t : HigherType, variance : Variance) -> Bool {
  // 変性チェックの実装（簡略化）
  match variance {
    Bivariant => true
    _ => true // TODO: 実際の変性チェック
  }
}

// 条件型の評価
pub fn evaluate_conditional(
  check_type : HigherType,
  extends_type : HigherType,
  true_type : HigherType,
  false_type : HigherType,
  context : TypeInferenceContext
) -> HigherType {
  if check_type.is_subtype_of(extends_type) {
    true_type
  } else {
    false_type
  }
}

// 型レベルのパターンマッチング（infer）
pub fn extract_type_with_infer(
  pattern : HigherType,
  target : HigherType,
  infer_name : String
) -> HigherType? {
  match (pattern, target) {
    // Promise<infer R> matches Promise<String> => R = String
    (TypeApplication(p_ctor, p_args), TypeApplication(t_ctor, t_args)) => {
      if p_ctor == t_ctor && p_args.length() == t_args.length() {
        for i in 0..<p_args.length() {
          match p_args[i] {
            HigherTypeParam(name, _) if name == infer_name => {
              return Some(t_args[i])
            }
            _ => ()
          }
        }
      }
      None
    }
    _ => None
  }
}

// ヘルパー関数
fn occurs_check_higher(var_name : String, t : HigherType) -> Bool {
  match t {
    HigherTypeParam(name, _) => name == var_name
    TypeApplication(f, args) => {
      occurs_check_higher(var_name, f) || 
      args.any(fn(arg) { occurs_check_higher(var_name, arg) })
    }
    Base(lt) => occurs_check(var_name, lt)
    Forall(_, body) => occurs_check_higher(var_name, body)
    Exists(_, body) => occurs_check_higher(var_name, body)
    TypeLambda(_, body) => occurs_check_higher(var_name, body)
    _ => false
  }
}

fn apply_higher_substitution(
  t : HigherType,
  subst : Map[String, HigherType]
) -> HigherType {
  match t {
    HigherTypeParam(name, kind) => subst.get(name).unwrap_or(t)
    TypeApplication(f, args) => {
      TypeApplication(
        apply_higher_substitution(f, subst),
        args.map(fn(arg) { apply_higher_substitution(arg, subst) })
      )
    }
    Base(lt) => Base(lt) // TODO: LambdaType内の置換も必要
    Forall(params, body) => {
      Forall(params, apply_higher_substitution(body, subst))
    }
    _ => t
  }
}

fn rename_type_params(
  t : HigherType,
  old_params : Array[TypeParam],
  new_params : Array[TypeParam]
) -> HigherType {
  let renaming = Map::new()
  for i in 0..<old_params.length() {
    renaming[old_params[i].name] = HigherTypeParam(new_params[i].name, new_params[i].kind)
  }
  apply_higher_substitution(t, renaming)
}

fn kind_to_string(k : Kind) -> String {
  match k {
    Type => "*"
    Arrow(k1, k2) => kind_to_string(k1) + " -> " + kind_to_string(k2)
  }
}