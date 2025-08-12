// 言語非依存の型表現
// TypeScriptの表現力を基準に、各言語に変換可能な中間表現

pub enum UniversalType {
  // 基本型
  String
  Number
  Integer
  Float
  Boolean
  Null
  Undefined
  Unknown
  Any
  Never
  Void
  
  // 複合型
  Array(UniversalType)
  Tuple(Array[UniversalType])
  Object(Map[String, ObjectField])
  Record(UniversalType, UniversalType) // key type, value type
  Map(UniversalType, UniversalType)
  Set(UniversalType)
  
  // 関数型
  Function(FunctionSignature)
  
  // 高度な型
  Union(Array[UniversalType])
  Intersection(Array[UniversalType])
  Optional(UniversalType) // T | null | undefined
  Nullable(UniversalType) // T | null
  
  // ジェネリック関連
  TypeParameter(String, TypeConstraint?)
  TypeApplication(String, Array[UniversalType]) // Generic<T, U>
  
  // 参照型
  TypeReference(String) // 名前付き型への参照
  
  // 条件型
  Conditional(UniversalType, UniversalType, UniversalType, UniversalType) // check, extends, true_type, false_type
  
  // リテラル型
  StringLiteral(String)
  NumberLiteral(Float)
  BooleanLiteral(Bool)
  
  // 特殊型
  Promise(UniversalType)
  Async(UniversalType)
  Result(UniversalType, UniversalType) // Ok type, Error type
  Option(UniversalType) // Some(T) | None
}

pub struct ObjectField {
  field_type : UniversalType
  optional : Bool
  is_readonly : Bool
  description : String?
}

pub struct FunctionSignature {
  type_parameters : Array[TypeParameter]
  parameters : Array[FunctionParameter]
  return_type : UniversalType
  is_async : Bool
  throws : UniversalType?
}

pub struct TypeParameter {
  name : String
  constraint : TypeConstraint?
  default : UniversalType?
  variance : Variance?
}

pub enum TypeConstraint {
  Extends(UniversalType)
  Super(UniversalType)
  Implements(Array[String]) // インターフェース名
}

pub enum Variance {
  Covariant     // out T (TypeScript: T extends unknown)
  Contravariant // in T
  Invariant     // in out T
}

pub struct FunctionParameter {
  name : String
  param_type : UniversalType
  optional : Bool
  default_value : String? // 言語固有の表現として文字列で保持
  is_rest : Bool // ...args
}

// 言語固有の機能サポート情報
pub struct LanguageCapabilities {
  // 基本的な型機能
  supports_generics : Bool
  supports_type_parameters : Bool
  supports_variance : Bool
  supports_higher_kinded_types : Bool
  
  // 高度な型機能
  supports_union_types : Bool
  supports_intersection_types : Bool
  supports_conditional_types : Bool
  supports_mapped_types : Bool
  supports_template_literals : Bool
  
  // 関数関連
  supports_async : Bool
  supports_generators : Bool
  supports_overloading : Bool
  supports_optional_params : Bool
  supports_default_params : Bool
  supports_rest_params : Bool
  
  // オブジェクト関連
  supports_readonly : Bool
  supports_optional_properties : Bool
  supports_index_signatures : Bool
  
  // 特殊な型
  supports_never : Bool
  supports_unknown : Bool
  supports_any : Bool
  supports_void : Bool
  supports_undefined : Bool
  supports_null : Bool
  
  // 型推論
  supports_type_inference : Bool
  supports_return_type_inference : Bool
  supports_generic_inference : Bool
}

// 各言語の能力定義
pub fn typescript_capabilities() -> LanguageCapabilities {
  {
    supports_generics: true,
    supports_type_parameters: true,
    supports_variance: true,
    supports_higher_kinded_types: false,
    supports_union_types: true,
    supports_intersection_types: true,
    supports_conditional_types: true,
    supports_mapped_types: true,
    supports_template_literals: true,
    supports_async: true,
    supports_generators: true,
    supports_overloading: true,
    supports_optional_params: true,
    supports_default_params: true,
    supports_rest_params: true,
    supports_readonly: true,
    supports_optional_properties: true,
    supports_index_signatures: true,
    supports_never: true,
    supports_unknown: true,
    supports_any: true,
    supports_void: true,
    supports_undefined: true,
    supports_null: true,
    supports_type_inference: true,
    supports_return_type_inference: true,
    supports_generic_inference: true,
  }
}

pub fn moonbit_capabilities() -> LanguageCapabilities {
  {
    supports_generics: true,
    supports_type_parameters: true,
    supports_variance: false,
    supports_higher_kinded_types: true,
    supports_union_types: false, // enumで代替
    supports_intersection_types: false,
    supports_conditional_types: false,
    supports_mapped_types: false,
    supports_template_literals: false,
    supports_async: false, // Result型で代替
    supports_generators: false,
    supports_overloading: false,
    supports_optional_params: false, // Option型で代替
    supports_default_params: true,
    supports_rest_params: false,
    supports_readonly: false, // デフォルトでimmutable
    supports_optional_properties: false, // Option型で代替
    supports_index_signatures: false,
    supports_never: false,
    supports_unknown: false,
    supports_any: false,
    supports_void: true, // Unit型
    supports_undefined: false,
    supports_null: false, // Option型で代替
    supports_type_inference: true,
    supports_return_type_inference: true,
    supports_generic_inference: true,
  }
}

pub fn python_pyright_capabilities() -> LanguageCapabilities {
  {
    supports_generics: true,
    supports_type_parameters: true,
    supports_variance: true,
    supports_higher_kinded_types: false,
    supports_union_types: true,
    supports_intersection_types: false, // Protocol で部分的に代替
    supports_conditional_types: false,
    supports_mapped_types: false,
    supports_template_literals: false,
    supports_async: true,
    supports_generators: true,
    supports_overloading: true,
    supports_optional_params: true,
    supports_default_params: true,
    supports_rest_params: true, // *args, **kwargs
    supports_readonly: false, // Final で部分的に代替
    supports_optional_properties: true,
    supports_index_signatures: false, // TypedDict で部分的に代替
    supports_never: true, // NoReturn
    supports_unknown: false, // Any で代替
    supports_any: true,
    supports_void: false, // None で代替
    supports_undefined: false, // None で代替
    supports_null: false, // None で代替
    supports_type_inference: true,
    supports_return_type_inference: false, // 明示的な型注釈が推奨
    supports_generic_inference: true,
  }
}

// 型の検証
pub fn validate_for_language(
  universal_type : UniversalType,
  capabilities : LanguageCapabilities
) -> Result[Unit, String] {
  match universal_type {
    Union(_) => {
      if not(capabilities.supports_union_types) {
        Err("Union types are not supported in this language")
      } else {
        Ok(())
      }
    }
    Intersection(_) => {
      if not(capabilities.supports_intersection_types) {
        Err("Intersection types are not supported in this language")
      } else {
        Ok(())
      }
    }
    Conditional(_, _, _, _) => {
      if not(capabilities.supports_conditional_types) {
        Err("Conditional types are not supported in this language")
      } else {
        Ok(())
      }
    }
    Never => {
      if not(capabilities.supports_never) {
        Err("Never type is not supported in this language")
      } else {
        Ok(())
      }
    }
    Unknown => {
      if not(capabilities.supports_unknown) {
        Err("Unknown type is not supported in this language")
      } else {
        Ok(())
      }
    }
    Any => {
      if not(capabilities.supports_any) {
        Err("Any type is not supported in this language")
      } else {
        Ok(())
      }
    }
    Void => {
      if not(capabilities.supports_void) {
        Err("Void type is not supported in this language")
      } else {
        Ok(())
      }
    }
    Undefined => {
      if not(capabilities.supports_undefined) {
        Err("Undefined type is not supported in this language")
      } else {
        Ok(())
      }
    }
    Null => {
      if not(capabilities.supports_null) {
        Err("Null type is not supported in this language")
      } else {
        Ok(())
      }
    }
    Promise(inner) => {
      if not(capabilities.supports_async) {
        Err("Async/Promise types are not supported in this language")
      } else {
        validate_for_language(inner, capabilities)
      }
    }
    Function(sig) => {
      if sig.is_async && not(capabilities.supports_async) {
        Err("Async functions are not supported in this language")
      } else if sig.type_parameters.length() > 0 && not(capabilities.supports_generics) {
        Err("Generic functions are not supported in this language")
      } else {
        Ok(())
      }
    }
    _ => Ok(())
  }
}