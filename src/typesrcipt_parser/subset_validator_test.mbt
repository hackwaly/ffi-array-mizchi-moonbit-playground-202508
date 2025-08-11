// Tests for TypeScript subset validator

test "validate primitive types" {
  // All primitive types should be supported
  inspect!(is_supported_type(Type::String), content="true")
  inspect!(is_supported_type(Type::Number), content="true")
  inspect!(is_supported_type(Type::Boolean), content="true")
  inspect!(is_supported_type(Type::Void), content="true")
  inspect!(is_supported_type(Type::Null), content="true")
  inspect!(is_supported_type(Type::Undefined), content="true")
  inspect!(is_supported_type(Type::Any), content="true")
  inspect!(is_supported_type(Type::Unknown), content="true")
  
  // Never type should not be supported
  inspect!(is_supported_type(Type::Never), content="false")
}

test "validate array types" {
  // Array of primitive types should be supported
  inspect!(is_supported_type(Type::Array(Type::String)), content="true")
  inspect!(is_supported_type(Type::Array(Type::Number)), content="true")
  
  // Nested arrays should be supported
  inspect!(is_supported_type(Type::Array(Type::Array(Type::String))), content="true")
  
  // Array of unsupported type should not be supported
  inspect!(is_supported_type(Type::Array(Type::Never)), content="false")
}

test "validate type references" {
  // Promise should be supported
  let promise_type = Type::TypeReference("Promise", [Type::String])
  inspect!(is_supported_type(promise_type), content="true")
  
  // DOM types should be supported
  inspect!(is_supported_type(Type::TypeReference("HTMLElement", [])), content="true")
  inspect!(is_supported_type(Type::TypeReference("Document", [])), content="true")
  
  // mbt.* types should be supported
  inspect!(is_supported_type(Type::TypeReference("mbt.String", [])), content="true")
  inspect!(is_supported_type(Type::TypeReference("mbt.Custom", [])), content="true")
  
  // Generic types with supported type args should be supported
  let generic_type = Type::TypeReference("Container", [Type::String, Type::Number])
  inspect!(is_supported_type(generic_type), content="true")
}

test "validate function types" {
  // Simple function type
  let simple_func = Type::Function({
    params: [
      { name: "x", type_: Type::Number, optional: false, rest: false }
    ],
    return_type: Type::String
  })
  inspect!(is_supported_type(simple_func), content="true")
  
  // Function with multiple parameters
  let multi_param_func = Type::Function({
    params: [
      { name: "a", type_: Type::String, optional: false, rest: false },
      { name: "b", type_: Type::Number, optional: true, rest: false }
    ],
    return_type: Type::Boolean
  })
  inspect!(is_supported_type(multi_param_func), content="true")
  
  // Function with unsupported parameter type
  let unsupported_func = Type::Function({
    params: [
      { name: "x", type_: Type::Never, optional: false, rest: false }
    ],
    return_type: Type::Void
  })
  inspect!(is_supported_type(unsupported_func), content="false")
}

test "validate object types" {
  // Simple object type
  let obj_type = Type::Object(
    Map::from_array([
      ("name", Type::String),
      ("age", Type::Number)
    ])
  )
  inspect!(is_supported_type(obj_type), content="true")
  
  // Object with unsupported property type
  let unsupported_obj = Type::Object(
    Map::from_array([
      ("valid", Type::String),
      ("invalid", Type::Never)
    ])
  )
  inspect!(is_supported_type(unsupported_obj), content="false")
}

test "validate union types" {
  // Nullable union should be supported
  let nullable_union = Type::Union([Type::String, Type::Null])
  inspect!(is_supported_type(nullable_union), content="true")
  
  let optional_union = Type::Union([Type::Number, Type::Undefined])
  inspect!(is_supported_type(optional_union), content="true")
  
  let full_optional = Type::Union([Type::String, Type::Null, Type::Undefined])
  inspect!(is_supported_type(full_optional), content="true")
  
  // Complex union should not be supported
  let complex_union = Type::Union([Type::String, Type::Number])
  inspect!(is_supported_type(complex_union), content="false")
  
  // Single element union should be supported
  let single_union = Type::Union([Type::String])
  inspect!(is_supported_type(single_union), content="true")
}

test "validate intersection types" {
  // Intersection types should not be supported
  let intersection = Type::Intersection([Type::String, Type::Number])
  inspect!(is_supported_type(intersection), content="false")
}

test "validate tuple types" {
  // Simple tuple
  let simple_tuple = Type::Tuple([Type::String, Type::Number])
  inspect!(is_supported_type(simple_tuple), content="true")
  
  // Empty tuple
  let empty_tuple = Type::Tuple([])
  inspect!(is_supported_type(empty_tuple), content="true")
  
  // Tuple with unsupported type
  let unsupported_tuple = Type::Tuple([Type::String, Type::Never])
  inspect!(is_supported_type(unsupported_tuple), content="false")
}

test "validate literal types" {
  // All literal types should be supported
  inspect!(is_supported_type(Type::Literal(LiteralType::String("hello"))), content="true")
  inspect!(is_supported_type(Type::Literal(LiteralType::Number(42.0))), content="true")
  inspect!(is_supported_type(Type::Literal(LiteralType::Boolean(true))), content="true")
}

test "validate optional and readonly types" {
  // Optional types should be supported if inner type is supported
  inspect!(is_supported_type(Type::Optional(Type::String)), content="true")
  inspect!(is_supported_type(Type::Optional(Type::Never)), content="false")
  
  // Readonly types should be supported if inner type is supported
  inspect!(is_supported_type(Type::Readonly(Type::Number)), content="true")
  inspect!(is_supported_type(Type::Readonly(Type::Never)), content="false")
}

test "validate declarations" {
  // All declaration types should be supported
  let interface_decl = Declaration::Interface({
    name: "Test",
    type_params: [],
    extends: [],
    members: []
  })
  inspect!(is_supported_declaration(interface_decl), content="true")
  
  let type_alias = Declaration::TypeAlias({
    name: "TestAlias",
    type_params: [],
    type_: Type::String
  })
  inspect!(is_supported_declaration(type_alias), content="true")
  
  let function_decl = Declaration::Function({
    name: "testFunc",
    params: [],
    return_type: Type::Void,
    declare: false
  })
  inspect!(is_supported_declaration(function_decl), content="true")
}

test "validation result collection" {
  let result = ValidationResult::new()
  
  // Initially valid
  inspect!(result.is_valid, content="true")
  inspect!(result.errors.length(), content="0")
  inspect!(result.warnings.length(), content="0")
  
  // Add warning - should still be valid
  result.add_warning("Test warning")
  inspect!(result.is_valid, content="true")
  inspect!(result.warnings.length(), content="1")
  
  // Add error - should become invalid
  result.add_error("Test error")
  inspect!(result.is_valid, content="false")
  inspect!(result.errors.length(), content="1")
}

test "validate type with errors and warnings" {
  let result = ValidationResult::new()
  
  // Any type should generate warning
  validate_type(Type::Any, result)
  inspect!(result.warnings.length() > 0, content="true")
  inspect!(result.is_valid, content="true")
  
  // Never type should generate error
  let result2 = ValidationResult::new()
  validate_type(Type::Never, result2)
  inspect!(result2.errors.length() > 0, content="true")
  inspect!(result2.is_valid, content="false")
  
  // Complex union should generate error
  let result3 = ValidationResult::new()
  let complex_union = Type::Union([Type::String, Type::Number, Type::Boolean])
  validate_type(complex_union, result3)
  inspect!(result3.errors.length() > 0, content="true")
  inspect!(result3.is_valid, content="false")
}

test "validate interface with issues" {
  let result = ValidationResult::new()
  
  // Interface with index signature should generate error
  let interface_with_index = InterfaceDeclaration::{
    name: "TestInterface",
    type_params: [],
    extends: [],
    members: [
      InterfaceMember::IndexSignature({
        key_name: "key",
        key_type: Type::String,
        value_type: Type::Any,
        readonly_: false
      })
    ]
  }
  
  validate_interface(interface_with_index, result)
  inspect!(result.errors.length() > 0, content="true")
  inspect!(result.is_valid, content="false")
  
  // Interface with multiple inheritance should generate error
  let result2 = ValidationResult::new()
  let multi_inherit = InterfaceDeclaration::{
    name: "TestInterface",
    type_params: [],
    extends: ["Base1", "Base2"],
    members: []
  }
  
  validate_interface(multi_inherit, result2)
  inspect!(result2.errors.length() > 0, content="true")
  inspect!(result2.is_valid, content="false")
}

test "validate class with issues" {
  let result = ValidationResult::new()
  
  // Class with implements should generate error
  let class_with_implements = ClassDeclaration::{
    name: "TestClass",
    type_params: [],
    extends: None,
    implements: ["Interface1", "Interface2"],
    members: [],
    declare: false
  }
  
  validate_class(class_with_implements, result)
  inspect!(result.errors.length() > 0, content="true")
  inspect!(result.is_valid, content="false")
  
  // Class with private members should generate warning
  let result2 = ValidationResult::new()
  let class_with_private = ClassDeclaration::{
    name: "TestClass",
    type_params: [],
    extends: None,
    implements: [],
    members: [
      ClassMember::ClassProperty({
        name: "privateField",
        type_: Type::String,
        visibility: Visibility::Private,
        is_static: false,
        readonly_: false,
        optional: false
      })
    ],
    declare: false
  }
  
  validate_class(class_with_private, result2)
  inspect!(result2.warnings.length() > 0, content="true")
  inspect!(result2.is_valid, content="true")  // Should still be valid with warnings
}

test "feature support checks" {
  // Supported features
  inspect!(is_feature_supported(Feature::Generics), content="true")
  inspect!(is_feature_supported(Feature::TupleTypes), content="true")
  inspect!(is_feature_supported(Feature::RestParameters), content="true")
  inspect!(is_feature_supported(Feature::OptionalChaining), content="true")
  inspect!(is_feature_supported(Feature::Unions), content="true")
  
  // Not supported features
  inspect!(is_feature_supported(Feature::Intersections), content="false")
  inspect!(is_feature_supported(Feature::ConditionalTypes), content="false")
  inspect!(is_feature_supported(Feature::MappedTypes), content="false")
  inspect!(is_feature_supported(Feature::Decorators), content="false")
  inspect!(is_feature_supported(Feature::IndexSignatures), content="false")
}

test "validate complete DTS file" {
  // Create a simple DTS file with mixed valid and invalid content
  let file = DtsFile::{
    declarations: [
      // Valid interface
      Declaration::Interface({
        name: "ValidInterface",
        type_params: [],
        extends: [],
        members: [
          InterfaceMember::Property({
            name: "prop",
            type_: Type::String,
            optional: false,
            readonly_: false
          })
        ]
      }),
      // Invalid type alias with intersection
      Declaration::TypeAlias({
        name: "InvalidAlias",
        type_params: [],
        type_: Type::Intersection([Type::String, Type::Number])
      }),
      // Function with warning (any type)
      Declaration::Function({
        name: "warnFunc",
        params: [{
          name: "param",
          type_: Type::Any,
          optional: false,
          rest: false
        }],
        return_type: Type::Void,
        declare: false
      })
    ]
  }
  
  let result = validate_dts_file(file)
  
  // Should have errors due to intersection type
  inspect!(result.is_valid, content="false")
  inspect!(result.errors.length() > 0, content="true")
  
  // Should have warnings due to any type
  inspect!(result.warnings.length() > 0, content="true")
}