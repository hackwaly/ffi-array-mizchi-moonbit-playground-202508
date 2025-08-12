// サブタイプ関係の拡張実装

// 構造的サブタイピングのサポート
pub fn LambdaType::is_structural_subtype_of(self : LambdaType, other : LambdaType) -> Bool {
  match (self, other) {
    // 基本的なサブタイプ関係
    (_, Any) => true
    (Never, _) => true
    (t1, t2) if t1 == t2 => true
    
    // Null/Undefined の扱い
    (Null, Undefined) | (Undefined, Null) => false // 厳密に区別
    
    // Union型の分配則
    (Union(types), target) => {
      // Union型の全ての要素がtargetのサブタイプ
      // Union型の全ての要素がtargetのサブタイプ
      let mut all_subtype = true
      for t in types {
        if not(t.is_structural_subtype_of(target)) {
          all_subtype = false
          break
        }
      }
      all_subtype
    }
    
    (source, Union(types)) => {
      // sourceがUnion型のいずれかの要素のサブタイプ
      // sourceがUnion型のいずれかの要素のサブタイプ
      let mut any_subtype = false
      for t in types {
        if source.is_structural_subtype_of(t) {
          any_subtype = true
          break
        }
      }
      any_subtype
    }
    
    // Intersection型の分配則
    (Intersection(types), target) => {
      // Intersection型のいずれかの要素がtargetのサブタイプ
      // Intersection型のいずれかの要素がtargetのサブタイプ
      let mut any_subtype = false
      for t in types {
        if t.is_structural_subtype_of(target) {
          any_subtype = true
          break
        }
      }
      any_subtype
    }
    
    (source, Intersection(types)) => {
      // sourceが全てのIntersection要素のサブタイプ
      // sourceが全てのIntersection要素のサブタイプ
      let mut all_subtype = true
      for t in types {
        if not(source.is_structural_subtype_of(t)) {
          all_subtype = false
          break
        }
      }
      all_subtype
    }
    
    // 配列の共変性
    (Array(elem1), Array(elem2)) => elem1.is_structural_subtype_of(elem2)
    
    // タプルの構造的サブタイピング
    (Tuple(elems1), Tuple(elems2)) => {
      if elems1.length() < elems2.length() {
        return false
      }
      // より長いタプルは短いタプルのサブタイプ（余分な要素は無視）
      for i in 0..<elems2.length() {
        if not(elems1[i].is_structural_subtype_of(elems2[i])) {
          return false
        }
      }
      true
    }
    
    // 関数の反変・共変性
    (Function(f1), Function(f2)) => {
      // パラメータ数のチェック
      if f1.parameters.length() != f2.parameters.length() {
        return false
      }
      
      // パラメータは反変（contravariant）
      for i in 0..<f1.parameters.length() {
        let p1 = f1.parameters[i]
        let p2 = f2.parameters[i]
        
        // オプショナルパラメータの扱い
        if p1.optional && not(p2.optional) {
          return false
        }
        
        // 反変性：f2のパラメータ型がf1のパラメータ型のサブタイプ
        if not(p2.param_type.is_structural_subtype_of(p1.param_type)) {
          return false
        }
      }
      
      // 戻り値は共変（covariant）
      if not(f1.return_type.is_structural_subtype_of(f2.return_type)) {
        return false
      }
      
      // 例外型も共変
      match (f1.throws, f2.throws) {
        (None, Some(_)) => false // f1が例外を投げないのにf2が投げる場合は不適合
        (Some(t1), Some(t2)) => t1.is_structural_subtype_of(t2)
        _ => true
      }
    }
    
    // 非同期型の共変性
    (Async(a1), Async(a2)) => a1.is_subtype_of(a2)
    
    // Result型の共変性
    (Result(r1), Result(r2)) => r1.is_subtype_of(r2)
    
    // Effect型のサブタイピング
    (Effect(e1, t1), Effect(e2, t2)) => {
      // エフェクトは同一で、内部型が共変
      e1 == e2 && t1.is_structural_subtype_of(t2)
    }
    
    // 型パラメータ
    (TypeParameter(name1), TypeParameter(name2)) => name1 == name2
    
    // Named型の名前的サブタイピング
    (Named(name1, args1), Named(name2, args2)) => {
      if name1 != name2 {
        return false
      }
      if args1.length() != args2.length() {
        return false
      }
      // 型引数の共変性（簡単のため）
      for i in 0..<args1.length() {
        if not(args1[i].is_structural_subtype_of(args2[i])) {
          return false
        }
      }
      true
    }
    
    // Schemaタイプの特殊ルール
    (Schema("integer"), Schema("number")) => true // integerはnumberのサブタイプ
    
    _ => false
  }
}

// 型の互換性チェック（双方向）
pub fn LambdaType::is_compatible_with(self : LambdaType, other : LambdaType) -> Bool {
  self.is_structural_subtype_of(other) || other.is_structural_subtype_of(self)
}

// 関数の引数としての代入可能性
pub fn can_assign_to_parameter(
  arg_type : LambdaType,
  param : Parameter
) -> Bool {
  // オプショナルパラメータへのnull/undefined代入
  if param.optional {
    match arg_type {
      Null | Undefined => return true
      Union(types) => {
        // UnionにNull/Undefinedが含まれていれば代入可能
        for t in types {
          match t {
            Null | Undefined => return true
            _ => ()
          }
        }
      }
      _ => ()
    }
  }
  
  // 通常のサブタイプチェック
  arg_type.is_structural_subtype_of(param.param_type)
}

// 最小上界（Least Upper Bound）の計算
pub fn LambdaType::lub(types : Array[LambdaType]) -> LambdaType {
  if types.is_empty() {
    return Never
  }
  if types.length() == 1 {
    return types[0]
  }
  
  // 同じ型が複数ある場合は単純化
  let mut unique_types = Array::new()
  for t in types {
    let mut exists = false
    for u in unique_types {
      if u == t {
        exists = true
        break
      }
    }
    if not(exists) {
      unique_types.push(t)
    }
  }
  
  // Anyが含まれていればAny
  for t in unique_types {
    match t {
      Any => return Any
      _ => ()
    }
  }
  
  // Neverは無視
  let mut non_never_types = Array::new()
  for t in unique_types {
    match t {
      Never => ()
      _ => non_never_types.push(t)
    }
  }
  if non_never_types.is_empty() {
    return Never
  }
  if non_never_types.length() == 1 {
    return non_never_types[0]
  }
  
  // それ以外はUnion型
  Union(non_never_types)
}

// 最大下界（Greatest Lower Bound）の計算
pub fn LambdaType::glb(types : Array[LambdaType]) -> LambdaType {
  if types.is_empty() {
    return Any
  }
  if types.length() == 1 {
    return types[0]
  }
  
  // Neverが含まれていればNever
  for t in types {
    match t {
      Never => return Never
      _ => ()
    }
  }
  
  // Anyは無視
  let mut non_any_types = Array::new()
  for t in types {
    match t {
      Any => ()
      _ => non_any_types.push(t)
    }
  }
  if non_any_types.is_empty() {
    return Any
  }
  if non_any_types.length() == 1 {
    return non_any_types[0]
  }
  
  // それ以外はIntersection型
  Intersection(non_any_types)
}