// 型推論と型チェック機能の強化

pub struct TypeInferenceContext {
  mut type_vars : Map[String, LambdaType]
  mut constraints : Array[InferenceConstraint]
  type_registry : TypeRegistry
}

pub struct InferenceConstraint {
  left : LambdaType
  right : LambdaType
  kind : ConstraintKind
}

pub enum ConstraintKind {
  Equal
  Subtype
  Supertype
}

pub fn TypeInferenceContext::new(registry : TypeRegistry) -> TypeInferenceContext {
  {
    type_vars: Map::new(),
    constraints: Array::new(),
    type_registry: registry
  }
}

// 型変数の生成
pub fn fresh_type_var(self : TypeInferenceContext, prefix : String) -> LambdaType {
  let mut counter = 0
  let mut name = prefix + counter.to_string()
  while self.type_vars.contains(name) {
    counter += 1
    name = prefix + counter.to_string()
  }
  let type_var = TypeParameter(name)
  self.type_vars[name] = type_var
  type_var
}

// 制約の追加
pub fn add_constraint(
  self : TypeInferenceContext,
  left : LambdaType,
  right : LambdaType,
  kind : ConstraintKind
) -> Unit {
  self.constraints.push({ left: left, right: right, kind: kind })
}

// 関数合成の型推論
pub fn compose_functions(
  f : FunctionType,
  g : FunctionType,
  context : TypeInferenceContext
) -> Result[FunctionType, String] {
  // g(f(x)) の形で合成
  // f: A -> B, g: B -> C => g∘f: A -> C
  
  // fの戻り値型とgの引数型の互換性チェック
  if g.parameters.length() != 1 {
    return Err("Second function must have exactly one parameter for composition")
  }
  
  let g_param_type = g.parameters[0].param_type
  
  // 型の単一化
  match unify(f.return_type, g_param_type, context) {
    Ok(substitution) => {
      // 合成関数の型を構築
      let composed_func : FunctionType = {
        name: None,
        type_parameters: Array::new(),
        parameters: f.parameters,
        return_type: apply_substitution(g.return_type, substitution),
        throws: merge_throws(f.throws, g.throws)
      }
      
      Ok(composed_func)
    }
    Err(msg) => Err("Cannot compose functions: " + msg)
  }
}

// 型の単一化（ユニフィケーション）
pub fn unify(
  t1 : LambdaType,
  t2 : LambdaType,
  context : TypeInferenceContext
) -> Result[Map[String, LambdaType], String] {
  let substitution = Map::new()
  if unify_impl(t1, t2, substitution, context) {
    Ok(substitution)
  } else {
    Err("Cannot unify types: " + type_to_string(t1) + " and " + type_to_string(t2))
  }
}

fn unify_impl(
  t1 : LambdaType,
  t2 : LambdaType,
  subst : Map[String, LambdaType],
  context : TypeInferenceContext
) -> Bool {
  let t1_subst = apply_substitution(t1, subst)
  let t2_subst = apply_substitution(t2, subst)
  
  match (t1_subst, t2_subst) {
    // 同じ型
    _ if t1_subst == t2_subst => true
    
    // 型変数
    (TypeParameter(v1), t2) => {
      if occurs_check(v1, t2) {
        false
      } else {
        subst[v1] = t2
        true
      }
    }
    
    (t1, TypeParameter(v2)) => {
      if occurs_check(v2, t1) {
        false
      } else {
        subst[v2] = t1
        true
      }
    }
    
    // Any型
    (Any, _) | (_, Any) => true
    
    // 配列型
    (Array(e1), Array(e2)) => unify_impl(e1, e2, subst, context)
    
    // タプル型
    (Tuple(es1), Tuple(es2)) => {
      if es1.length() != es2.length() {
        return false
      }
      for i in 0..<es1.length() {
        if not(unify_impl(es1[i], es2[i], subst, context)) {
          return false
        }
      }
      true
    }
    
    // Union型
    (Union(ts1), Union(ts2)) => {
      // 単純化：要素数が同じ場合のみ単一化可能とする
      if ts1.length() != ts2.length() {
        return false
      }
      // TODO: より洗練された単一化アルゴリズム
      true
    }
    
    // 関数型
    (Function(f1), Function(f2)) => {
      if f1.parameters.length() != f2.parameters.length() {
        return false
      }
      
      // パラメータの単一化
      for i in 0..<f1.parameters.length() {
        if not(unify_impl(f1.parameters[i].param_type, f2.parameters[i].param_type, subst, context)) {
          return false
        }
      }
      
      // 戻り値の単一化
      unify_impl(f1.return_type, f2.return_type, subst, context)
    }
    
    _ => false
  }
}

// 出現チェック（循環参照の防止）
fn occurs_check(var_name : String, t : LambdaType) -> Bool {
  match t {
    TypeParameter(name) => name == var_name
    Array(elem) => occurs_check(var_name, elem)
    Tuple(elems) => {
      for e in elems {
        if occurs_check(var_name, e) {
          return true
        }
      }
      false
    }
    Union(types) => {
      for t in types {
        if occurs_check(var_name, t) {
          return true
        }
      }
      false
    }
    Intersection(types) => {
      for t in types {
        if occurs_check(var_name, t) {
          return true
        }
      }
      false
    }
    Function(f) => {
      let mut param_occurs = false
      for p in f.parameters {
        if occurs_check(var_name, p.param_type) {
          param_occurs = true
          break
        }
      }
      param_occurs ||
      occurs_check(var_name, f.return_type) ||
      f.throws.map(fn(t) { occurs_check(var_name, t) }).unwrap_or(false)
    }
    _ => false
  }
}

// 代入の適用
fn apply_substitution(t : LambdaType, subst : Map[String, LambdaType]) -> LambdaType {
  match t {
    TypeParameter(name) => subst.get(name).unwrap_or(t)
    Array(elem) => Array(apply_substitution(elem, subst))
    Tuple(elems) => Tuple(elems.map(fn(e) { apply_substitution(e, subst) }))
    Union(types) => Union(types.map(fn(t) { apply_substitution(t, subst) }))
    Intersection(types) => Intersection(types.map(fn(t) { apply_substitution(t, subst) }))
    Function(f) => {
      Function({
        ..f,
        parameters: f.parameters.map(fn(p) {
          { ..p, param_type: apply_substitution(p.param_type, subst) }
        }),
        return_type: apply_substitution(f.return_type, subst),
        throws: f.throws.map(fn(t) { apply_substitution(t, subst) })
      })
    }
    _ => t
  }
}

// 例外型のマージ
fn merge_throws(t1 : LambdaType?, t2 : LambdaType?) -> LambdaType? {
  match (t1, t2) {
    (None, None) => None
    (Some(t), None) | (None, Some(t)) => Some(t)
    (Some(t1), Some(t2)) => {
      // 両方の例外をUnion型でまとめる
      match (t1, t2) {
        (Union(ts1), Union(ts2)) => {
          let mut all_types = Array::new()
          for t in ts1 {
            all_types.push(t)
          }
          for t in ts2 {
            all_types.push(t)
          }
          Some(Union(all_types))
        }
        (Union(ts), t) | (t, Union(ts)) => {
          let mut all_types = Array::new()
          for x in ts {
            all_types.push(x)
          }
          all_types.push(t)
          Some(Union(all_types))
        }
        _ => Some(Union([t1, t2]))
      }
    }
  }
}

// 型の簡約化
pub fn simplify_type(t : LambdaType) -> LambdaType {
  match t {
    Union(types) => {
      // 重複を除去
      let mut unique_types = Array::new()
      for t in types {
        let simplified = simplify_type(t)
        let mut exists = false
        for u in unique_types {
          if u == simplified {
            exists = true
            break
          }
        }
        if not(exists) {
          unique_types.push(simplified)
        }
      }
      
      // Anyが含まれていればAny
      for t in unique_types {
        match t {
          Any => return Any
          _ => ()
        }
      }
      
      // Neverを除去
      let mut non_never = Array::new()
      for t in unique_types {
        match t {
          Never => ()
          _ => non_never.push(t)
        }
      }
      
      match non_never.length() {
        0 => Never
        1 => non_never[0]
        _ => Union(non_never)
      }
    }
    
    Intersection(types) => {
      // Neverが含まれていればNever
      for t in types {
        match t {
          Never => return Never
          _ => ()
        }
      }
      
      // Anyを除去
      let mut non_any = Array::new()
      for t in types {
        match t {
          Any => ()
          _ => non_any.push(t)
        }
      }
      
      match non_any.length() {
        0 => Any
        1 => non_any[0]
        _ => Intersection(non_any)
      }
    }
    
    _ => t
  }
}