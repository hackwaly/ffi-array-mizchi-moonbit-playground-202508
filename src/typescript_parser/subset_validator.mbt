// TypeScript to MoonBit subset validator
// Defines and validates the supported subset of TypeScript that can be translated to MoonBit

// Validation result
pub struct ValidationResult {
  mut is_valid : Bool
  errors : Array[String]
  warnings : Array[String]
} derive(Show)

// Create a new validation result
pub fn ValidationResult::new() -> ValidationResult {
  { is_valid: true, errors: [], warnings: [] }
}

// Add error to validation result
pub fn ValidationResult::add_error(self : ValidationResult, error : String) -> Unit {
  self.is_valid = false
  self.errors.push(error)
}

// Add warning to validation result
pub fn ValidationResult::add_warning(self : ValidationResult, warning : String) -> Unit {
  self.warnings.push(warning)
}

// Check if a type is supported
pub fn is_supported_type(typ : Type) -> Bool {
  match typ {
    // Primitive types
    String | Number | Boolean | Void | Null | Undefined => true
    
    // Any and Unknown are supported but with warnings
    Any | Unknown => true
    
    // Never type is not supported
    Never => false
    
    // Array type is supported if element type is supported
    Array(element_type) => is_supported_type(element_type)
    
    // Type references
    TypeReference(name, type_args) => {
      // Check for supported type references
      match name {
        // Promise is supported
        "Promise" => type_args.all(fn(t) { is_supported_type(t) })
        
        // DOM types are mapped to JSValue
        "HTMLElement" | "Element" | "Document" | "Window" | 
        "Event" | "MouseEvent" | "KeyboardEvent" => true
        
        // mbt.* prefixed types are supported
        _ => {
          if name.length() > 4 && name.substring(0, 4) == "mbt." {
            type_args.all(fn(t) { is_supported_type(t) })
          } else {
            // Other type references are allowed if their type arguments are supported
            type_args.all(fn(t) { is_supported_type(t) })
          }
        }
      }
    }
    
    // Function types are supported if all parameter and return types are supported
    Function(func_type) => {
      func_type.params.all(fn(p) { is_supported_type(p.type_) }) &&
      is_supported_type(func_type.return_type)
    }
    
    // Object types are supported if all property types are supported
    Object(props) => {
      let mut all_supported = true
      props.each(fn(_, typ) {
        if not(is_supported_type(typ)) {
          all_supported = false
        }
      })
      all_supported
    }
    
    // Tuple types are supported if all element types are supported
    Tuple(types) => types.all(fn(t) { is_supported_type(t) })
    
    // Union and Intersection types have limited support
    Union(types) => {
      // Union types are only supported if they can be simplified
      // For now, we only support unions with null/undefined
      types.all(fn(t) { 
        match t {
          Null | Undefined => true
          _ => false
        }
      }) || types.length() == 1
    }
    
    Intersection(_) => false  // Not supported
    
    // Literal types are supported
    Literal(_) => true
    
    // Optional and Readonly modifiers are supported
    Optional(inner) => is_supported_type(inner)
    Readonly(inner) => is_supported_type(inner)
  }
}

// Check if a declaration is supported
pub fn is_supported_declaration(decl : Declaration) -> Bool {
  match decl {
    // Supported declarations
    Interface(_) | TypeAlias(_) | Function(_) | Variable(_) | 
    Class(_) | Enum(_) => true
    
    // Module and Namespace declarations are supported
    Module(_) | Namespace(_) => true
    
    // Export and Import are supported
    Export(_) | Import(_) => true
  }
}

// Validate a type and collect errors/warnings
pub fn validate_type(typ : Type, result : ValidationResult) -> Unit {
  match typ {
    // Warn about Any and Unknown usage
    Any => result.add_warning("'any' type loses type safety")
    Unknown => result.add_warning("'unknown' type requires type guards")
    
    // Error on Never type
    Never => result.add_error("'never' type is not supported")
    
    // Validate nested types
    Array(element_type) => validate_type(element_type, result)
    
    TypeReference(name, type_args) => {
      // Validate type arguments
      type_args.each(fn(t) { validate_type(t, result) })
    }
    
    Function(func_type) => {
      // Validate parameter types
      func_type.params.each(fn(p) { validate_type(p.type_, result) })
      // Validate return type
      validate_type(func_type.return_type, result)
      
      // Warn about rest parameters
      func_type.params.each(fn(p) {
        if p.rest {
          result.add_warning("Rest parameters have limited support")
        }
      })
    }
    
    Object(props) => {
      // Validate property types
      props.each(fn(key, typ) { 
        validate_type(typ, result)
      })
    }
    
    Tuple(types) => {
      // Validate element types
      types.each(fn(t) { validate_type(t, result) })
      
      // Warn about large tuples
      if types.length() > 10 {
        result.add_warning("Large tuples may impact performance")
      }
    }
    
    Union(types) => {
      // Check if union can be handled
      let has_non_nullable = types.any(fn(t) {
        match t {
          Null | Undefined => false
          _ => true
        }
      })
      
      if has_non_nullable && types.length() > 1 {
        result.add_error("Complex union types are not supported (only nullable unions)")
      }
      
      // Validate member types
      types.each(fn(t) { validate_type(t, result) })
    }
    
    Intersection(_) => {
      result.add_error("Intersection types are not supported")
    }
    
    Optional(inner) => validate_type(inner, result)
    Readonly(inner) => validate_type(inner, result)
    
    _ => ()  // Other types don't need special validation
  }
}

// Validate an interface declaration
pub fn validate_interface(iface : InterfaceDeclaration, result : ValidationResult) -> Unit {
  // Check for generic constraints
  if iface.type_params.length() > 0 {
    result.add_warning("Generic type parameters have limited support")
  }
  
  // Check extends clause
  if iface.extends.length() > 1 {
    result.add_error("Multiple interface inheritance is not supported")
  }
  
  // Validate members
  iface.members.each(fn(mbr) {
    match mbr {
      Property(prop) => {
        validate_type(prop.type_, result)
        if prop.readonly_ {
          result.add_warning("Readonly properties are mapped to regular properties")
        }
      }
      Method(meth) => {
        meth.params.each(fn(p) { validate_type(p.type_, result) })
        validate_type(meth.return_type, result)
      }
      Constructor(_) => {
        result.add_error("Constructor signatures in interfaces are not supported")
      }
      IndexSignature(sig) => {
        result.add_error("Index signatures are not supported")
      }
    }
  })
}

// Validate a class declaration
pub fn validate_class(cls : ClassDeclaration, result : ValidationResult) -> Unit {
  // Check for abstract classes
  if cls.declare {
    result.add_warning("Declare classes are treated as regular classes")
  }
  
  // Check inheritance
  if cls.implements.length() > 0 {
    result.add_error("Class implements clause is not supported")
  }
  
  // Validate members
  cls.members.each(fn(mbr) {
    match mbr {
      ClassProperty(prop) => {
        validate_type(prop.type_, result)
        
        // Check visibility
        match prop.visibility {
          Private | Protected => {
            result.add_warning("Private/protected members are mapped to public")
          }
          _ => ()
        }
      }
      ClassMethod(meth) => {
        meth.params.each(fn(p) { validate_type(p.type_, result) })
        validate_type(meth.return_type, result)
        
        // Check visibility
        match meth.visibility {
          Private | Protected => {
            result.add_warning("Private/protected methods are mapped to public")
          }
          _ => ()
        }
      }
      ClassConstructor(ctor) => {
        ctor.params.each(fn(p) { validate_type(p.type_, result) })
      }
    }
  })
}

// Validate a function declaration
pub fn validate_function(func : FunctionDeclaration, result : ValidationResult) -> Unit {
  // Validate parameter types
  func.params.each(fn(p) { 
    validate_type(p.type_, result)
    if p.rest {
      result.add_warning("Rest parameters are mapped to arrays")
    }
  })
  
  // Validate return type
  validate_type(func.return_type, result)
  
  // Check for function overloads
  if func.declare {
    result.add_warning("Function declarations without implementation are ignored")
  }
}

// Validate a complete declaration
pub fn validate_declaration(decl : Declaration, result : ValidationResult) -> Unit {
  match decl {
    Interface(iface) => validate_interface(iface, result)
    
    TypeAlias(ta) => {
      validate_type(ta.type_, result)
      if ta.type_params.length() > 0 {
        result.add_warning("Generic type aliases have limited support")
      }
    }
    
    Function(func) => validate_function(func, result)
    
    Variable(v) => {
      validate_type(v.type_, result)
      if v.declare {
        result.add_warning("Declare variables are treated as regular variables")
      }
    }
    
    Class(cls) => validate_class(cls, result)
    
    Module(mod) => {
      if mod.declare {
        result.add_warning("Declare modules are treated as regular modules")
      }
      mod.declarations.each(fn(d) { validate_declaration(d, result) })
    }
    
    Namespace(ns) => {
      if ns.declare {
        result.add_warning("Declare namespaces are treated as regular namespaces")
      }
      ns.declarations.each(fn(d) { validate_declaration(d, result) })
    }
    
    Enum(enum_decl) => {
      enum_decl.members.each(fn(mbr) {
        match mbr.value {
          Some(Literal(lit)) => {
            match lit {
              String(_) | Number(_) => ()
              Boolean(_) => result.add_error("Boolean enum values are not supported")
            }
          }
          Some(_) => result.add_error("Complex enum values are not supported")
          None => ()
        }
      })
    }
    
    Export(exp) => {
      match exp.declaration {
        Some(d) => validate_declaration(d, result)
        None => ()
      }
    }
    
    Import(imp) => {
      if imp.is_type_only {
        result.add_warning("Type-only imports are treated as regular imports")
      }
    }
  }
}

// Main validation function for a DTS file
pub fn validate_dts_file(file : DtsFile) -> ValidationResult {
  let result = ValidationResult::new()
  
  // Validate all declarations
  file.declarations.each(fn(decl) {
    validate_declaration(decl, result)
  })
  
  result
}

// Check if a specific TypeScript feature is supported
pub enum Feature {
  Generics
  Unions
  Intersections
  ConditionalTypes
  MappedTypes
  TemplateLiterals
  Decorators
  Mixins
  AbstractClasses
  PrivateFields
  Overloads
  IndexSignatures
  ThisTypes
  TupleTypes
  RestParameters
  OptionalChaining
  NullishCoalescing
} derive(Show, Eq)

// Check if a feature is supported
pub fn is_feature_supported(feature : Feature) -> Bool {
  match feature {
    // Supported features
    Generics => true          // Basic generics are supported
    TupleTypes => true        // Tuples are supported
    RestParameters => true    // Rest parameters are mapped to arrays
    OptionalChaining => true  // Optional properties are supported
    
    // Partially supported features
    Unions => true            // Only nullable unions are fully supported
    
    // Not supported features
    Intersections => false
    ConditionalTypes => false
    MappedTypes => false
    TemplateLiterals => false
    Decorators => false
    Mixins => false
    AbstractClasses => false
    PrivateFields => false
    Overloads => false
    IndexSignatures => false
    ThisTypes => false
    NullishCoalescing => false
  }
}

// Get feature support message
pub fn get_feature_support_message(feature : Feature) -> String {
  match feature {
    Generics => "Basic generics are supported"
    Unions => "Only nullable unions (T | null | undefined) are supported"
    Intersections => "Intersection types are not supported"
    ConditionalTypes => "Conditional types are not supported"
    MappedTypes => "Mapped types are not supported"
    TemplateLiterals => "Template literal types are not supported"
    Decorators => "Decorators are not supported"
    Mixins => "Mixins are not supported"
    AbstractClasses => "Abstract classes are not supported"
    PrivateFields => "Private fields are mapped to public"
    Overloads => "Function overloads are not supported"
    IndexSignatures => "Index signatures are not supported"
    ThisTypes => "This types are not supported"
    TupleTypes => "Tuple types are supported"
    RestParameters => "Rest parameters are mapped to arrays"
    OptionalChaining => "Optional properties are supported"
    NullishCoalescing => "Nullish coalescing is not supported"
  }
}