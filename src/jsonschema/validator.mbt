// JSON Schema Validator implementation

///|
pub struct Validator {
  schema : Schema
}

///|
pub fn Validator::new(schema : Schema) -> Validator {
  Validator::{ schema }
}

///|
pub fn validate(self : Validator, value : Json) -> ValidationResult {
  let errors = validate_with_path(value, self.schema, "", "#")
  if errors.length() > 0 {
    Err(errors)
  } else {
    Ok
  }
}

// Pure function that returns errors instead of mutating state
fn validate_with_path(
  value : Json,
  schema : Schema,
  path : String,
  schema_path : String,
) -> Array[ValidationError] {
  validate_value(value, schema, path, schema_path)
}

///|
fn validate_value(
  value : Json,
  schema : Schema,
  path : String,
  schema_path : String,
) -> Array[ValidationError] {
  let errors : Array[ValidationError] = []
  
  match schema {
    Schema::Null =>
      match value {
        @json.Null => errors
        _ => {
          errors.push(ValidationError::new(format_path(path), "Value is not null", schema_path))
          errors
        }
      }
    
    Schema::Boolean =>
      match value {
        @json.True => errors
        @json.False => errors
        _ => {
          errors.push(ValidationError::new(format_path(path), "Value is not a boolean", schema_path))
          errors
        }
      }
    
    Schema::String(constraints) =>
      match value {
        @json.String(s) =>
          validate_string(s, constraints, path, schema_path)
        _ => {
          errors.push(ValidationError::new(format_path(path), "Value is not a string", schema_path))
          errors
        }
      }
    
    Schema::Number(constraints) =>
      match value {
        @json.Number(n, ..) =>
          validate_number(n, constraints, path, schema_path)
        _ => {
          errors.push(ValidationError::new(format_path(path), "Value is not a number", schema_path))
          errors
        }
      }
    
    Schema::Integer(constraints) =>
      match value {
        @json.Number(n, ..) =>
          if n.floor() != n {
            errors.push(ValidationError::new(format_path(path), "Value is not an integer", schema_path))
            errors
          } else {
            validate_number(n, constraints, path, schema_path)
          }
        _ => {
          errors.push(ValidationError::new(format_path(path), "Value is not a number", schema_path))
          errors
        }
      }
    
    Schema::Array(constraints) =>
      match value {
        @json.Array(arr) =>
          validate_array(arr, constraints, path, schema_path)
        _ => {
          errors.push(ValidationError::new(format_path(path), "Value is not an array", schema_path))
          errors
        }
      }
    
    Schema::Object(constraints) =>
      match value {
        @json.Object(obj) =>
          validate_object(obj, constraints, path, schema_path)
        _ => {
          errors.push(ValidationError::new(format_path(path), "Value is not an object", schema_path))
          errors
        }
      }
    
    Schema::EnumValues(allowed_values) => {
      let mut found = false
      for i = 0; i < allowed_values.length(); i = i + 1 {
        if json_equals(value, allowed_values[i]) {
          found = true
          break
        }
      }
      if not(found) {
        errors.push(ValidationError::new(format_path(path), "Value is not in the enumeration", schema_path))
      }
      errors
    }
    
    Schema::ConstValue(const_value) =>
      if not(json_equals(value, const_value)) {
        errors.push(ValidationError::new(format_path(path), "Value does not match const", schema_path))
        errors
      } else {
        errors
      }
    
    Schema::AnyOfSchemas(schemas) => {
      let mut any_valid = false
      for i = 0; i < schemas.length(); i = i + 1 {
        let sub_errors = validate_value(value, schemas[i], path, schema_path + "/anyOf[\{i}]")
        if sub_errors.length() == 0 {
          any_valid = true
          break
        }
      }
      if not(any_valid) {
        errors.push(ValidationError::new(format_path(path), "Value does not match any schema in anyOf", schema_path))
      }
      errors
    }
    
    Schema::AllOfSchemas(schemas) =>
      for i = 0; i < schemas.length(); i = i + 1 {
        errors.append(validate_value(value, schemas[i], path, schema_path + "/allOf[\{i}]"))
      } else {
        errors
      }
    
    Schema::OneOfSchemas(schemas) => {
      let mut valid_count = 0
      for i = 0; i < schemas.length(); i = i + 1 {
        let sub_errors = validate_value(value, schemas[i], path, schema_path + "/oneOf[\{i}]")
        if sub_errors.length() == 0 {
          valid_count = valid_count + 1
        }
      }
      if valid_count == 0 {
        errors.push(ValidationError::new(format_path(path), "Value does not match any schema in oneOf", schema_path))
      } else if valid_count > 1 {
        errors.push(ValidationError::new(format_path(path), "Value matches multiple schemas in oneOf", schema_path))
      }
      errors
    }
    
    Schema::NotSchema(not_schema) => {
      let sub_errors = validate_value(value, not_schema, path, schema_path + "/not")
      if sub_errors.length() == 0 {
        errors.push(ValidationError::new(format_path(path), "Value should not match the schema in 'not'", schema_path))
      }
      errors
    }
    
    Schema::If(if_schema, then_schema, else_schema) => {
      let if_errors = validate_value(value, if_schema, path, schema_path + "/if")
      if if_errors.length() == 0 {
        match then_schema {
          Some(schema) =>
            errors.append(validate_value(value, schema, path, schema_path + "/then"))
          None => ()
        }
      } else {
        match else_schema {
          Some(schema) =>
            errors.append(validate_value(value, schema, path, schema_path + "/else"))
          None => ()
        }
      }
      errors
    }
    
    Schema::Multiple(types) => {
      let mut valid = false
      for i = 0; i < types.length(); i = i + 1 {
        if check_type(value, types[i]) {
          valid = true
          break
        }
      }
      if not(valid) {
        errors.push(ValidationError::new(format_path(path), "Value does not match any of the allowed types", schema_path))
      }
      errors
    }
    
    Schema::Any =>
      // Any value is valid
      errors
    
    Schema::Ref(_ref_path) => {
      // Reference resolution would be implemented here
      errors.push(ValidationError::new(format_path(path), "Reference resolution not implemented", schema_path))
      errors
    }
  }
}

///|
fn validate_number(
  value : Double,
  constraints : NumberConstraints,
  path : String,
  schema_path : String,
) -> Array[ValidationError] {
  let errors : Array[ValidationError] = []
  
  // Minimum
  match constraints.minimum {
    Some(min) =>
      if value < min {
        errors.push(ValidationError::new(
          format_path(path),
          "Value \{value} is less than minimum \{min}",
          schema_path + "/minimum",
        ))
      }
    None => ()
  }

  // Maximum
  match constraints.maximum {
    Some(max) =>
      if value > max {
        errors.push(ValidationError::new(
          format_path(path),
          "Value \{value} is greater than maximum \{max}",
          schema_path + "/maximum",
        ))
      }
    None => ()
  }

  // Exclusive minimum
  match constraints.exclusive_minimum {
    Some(min) =>
      if value <= min {
        errors.push(ValidationError::new(
          format_path(path),
          "Value \{value} is not greater than exclusive minimum \{min}",
          schema_path + "/exclusiveMinimum",
        ))
      }
    None => ()
  }

  // Exclusive maximum
  match constraints.exclusive_maximum {
    Some(max) =>
      if value >= max {
        errors.push(ValidationError::new(
          format_path(path),
          "Value \{value} is not less than exclusive maximum \{max}",
          schema_path + "/exclusiveMaximum",
        ))
      }
    None => ()
  }

  // Multiple of
  match constraints.multiple_of {
    Some(divisor) =>
      if divisor > 0.0 {
        let remainder = value % divisor
        if remainder.abs() > 0.0000001 {
          errors.push(ValidationError::new(
            format_path(path),
            "Value \{value} is not a multiple of \{divisor}",
            schema_path + "/multipleOf",
          ))
        }
      }
    None => ()
  }
  
  errors
}

///|
fn validate_string(
  value : String,
  constraints : StringConstraints,
  path : String,
  schema_path : String,
) -> Array[ValidationError] {
  let errors : Array[ValidationError] = []
  let len = value.length()

  // Min length
  match constraints.min_length {
    Some(min) =>
      if len < min {
        errors.push(ValidationError::new(
          format_path(path),
          "String length \{len} is less than minimum \{min}",
          schema_path + "/minLength",
        ))
      }
    None => ()
  }

  // Max length
  match constraints.max_length {
    Some(max) =>
      if len > max {
        errors.push(ValidationError::new(
          format_path(path),
          "String length \{len} is greater than maximum \{max}",
          schema_path + "/maxLength",
        ))
      }
    None => ()
  }

  // Pattern validation would require regex support
  // Format validation would require format-specific checks
  
  errors
}

///|
fn validate_array(
  value : Array[Json],
  constraints : ArrayConstraints,
  path : String,
  schema_path : String,
) -> Array[ValidationError] {
  let errors : Array[ValidationError] = []
  let len = value.length()

  // Min items
  match constraints.min_items {
    Some(min) =>
      if len < min {
        errors.push(ValidationError::new(
          format_path(path),
          "Array length \{len} is less than minimum \{min}",
          schema_path + "/minItems",
        ))
      }
    None => ()
  }

  // Max items
  match constraints.max_items {
    Some(max) =>
      if len > max {
        errors.push(ValidationError::new(
          format_path(path),
          "Array length \{len} is greater than maximum \{max}",
          schema_path + "/maxItems",
        ))
      }
    None => ()
  }

  // Unique items
  match constraints.unique_items {
    Some(unique) =>
      if unique {
        for i = 0; i < len - 1; i = i + 1 {
          for j = i + 1; j < len; j = j + 1 {
            if json_equals(value[i], value[j]) {
              errors.push(ValidationError::new(
                format_path(path),
                "Array contains duplicate items at indices \{i} and \{j}",
                schema_path + "/uniqueItems",
              ))
            }
          }
        }
      }
    None => ()
  }

  // Prefix items validation (2020-12)
  match constraints.prefix_items {
    Some(prefix_schemas) => {
      let prefix_len = prefix_schemas.length()
      for i = 0; i < len && i < prefix_len; i = i + 1 {
        let item_path = path + "[\{i}]"
        errors.append(validate_value(
          value[i],
          prefix_schemas[i],
          item_path,
          schema_path + "/prefixItems[\{i}]",
        ))
      }
      // Items beyond prefix are validated by items schema
      match constraints.items {
        Some(item_schema) =>
          for i = prefix_len; i < len; i = i + 1 {
            let item_path = path + "[\{i}]"
            errors.append(validate_value(
              value[i],
              item_schema,
              item_path,
              schema_path + "/items",
            ))
          }
        None => ()
      }
    }
    None =>
      // Items validation (no prefix)
      match constraints.items {
        Some(item_schema) =>
          for i = 0; i < len; i = i + 1 {
            let item_path = path + "[\{i}]"
            errors.append(validate_value(
              value[i],
              item_schema,
              item_path,
              schema_path + "/items",
            ))
          }
        None => ()
      }
  }

  // Contains validation
  match constraints.contains {
    Some(contains_schema) => {
      let mut contains_count = 0
      for i = 0; i < len; i = i + 1 {
        let sub_errors = validate_value(value[i], contains_schema, path + "[\{i}]", schema_path + "/contains")
        if sub_errors.length() == 0 {
          contains_count = contains_count + 1
        }
      }

      // Check minContains
      match constraints.min_contains {
        Some(min) =>
          if contains_count < min {
            errors.push(ValidationError::new(
              format_path(path),
              "Array contains only \{contains_count} matching items, less than minimum \{min}",
              schema_path + "/minContains",
            ))
          }
        None =>
          // Default minContains is 1 if contains is present
          if contains_count < 1 {
            errors.push(ValidationError::new(
              format_path(path),
              "Array does not contain any item matching the schema",
              schema_path + "/contains",
            ))
          }
      }

      // Check maxContains
      match constraints.max_contains {
        Some(max) =>
          if contains_count > max {
            errors.push(ValidationError::new(
              format_path(path),
              "Array contains \{contains_count} matching items, more than maximum \{max}",
              schema_path + "/maxContains",
            ))
          }
        None => ()
      }
    }
    None => ()
  }
  
  errors
}

///|
fn validate_object(
  value : Map[String, Json],
  constraints : ObjectConstraints,
  path : String,
  schema_path : String,
) -> Array[ValidationError] {
  let errors : Array[ValidationError] = []
  
  // Required properties
  match constraints.required {
    Some(required_props) =>
      for i = 0; i < required_props.length(); i = i + 1 {
        let prop = required_props[i]
        if not(value.contains(prop)) {
          errors.push(ValidationError::new(
            format_path(path),
            "Required property '\{prop}' is missing",
            schema_path + "/required",
          ))
        }
      }
    None => ()
  }

  // Properties validation
  match constraints.properties {
    Some(props) =>
      props.each(fn(prop_name, prop_schema) {
        match value.get(prop_name) {
          Some(prop_value) => {
            let prop_path = if path == "" {
              prop_name
            } else {
              path + "." + prop_name
            }
            errors.append(validate_value(
              prop_value,
              prop_schema,
              prop_path,
              schema_path + "/properties/" + prop_name,
            ))
          }
          None => ()
        }
      })
    None => ()
  }

  // Additional properties
  match constraints.additional_properties {
    Some(add_schema) =>
      value.each(fn(key, val) {
        let is_defined = match constraints.properties {
          Some(props) => props.contains(key)
          None => false
        }
        if not(is_defined) {
          let prop_path = if path == "" { key } else { path + "." + key }
          errors.append(validate_value(
            val,
            add_schema,
            prop_path,
            schema_path + "/additionalProperties",
          ))
        }
      })
    None => ()
  }

  // Min/Max properties
  let prop_count = value.size()
  match constraints.min_properties {
    Some(min) =>
      if prop_count < min {
        errors.push(ValidationError::new(
          format_path(path),
          "Object has \{prop_count} properties, less than minimum \{min}",
          schema_path + "/minProperties",
        ))
      }
    None => ()
  }
  match constraints.max_properties {
    Some(max) =>
      if prop_count > max {
        errors.push(ValidationError::new(
          format_path(path),
          "Object has \{prop_count} properties, more than maximum \{max}",
          schema_path + "/maxProperties",
        ))
      }
    None => ()
  }
  
  errors
}

///|
fn check_type(value : Json, expected : SchemaType) -> Bool {
  match (value, expected) {
    (@json.Null, Null) => true
    (@json.True, Boolean) => true
    (@json.False, Boolean) => true
    (@json.Number(_, ..), Number) => true
    (@json.Number(n, ..), Integer) => n.floor() == n
    (@json.String(_), String) => true
    (@json.Array(_), Array) => true
    (@json.Object(_), Object) => true
    _ => false
  }
}

///|
fn json_equals(a : Json, b : Json) -> Bool {
  match (a, b) {
    (@json.Null, @json.Null) => true
    (@json.True, @json.True) => true
    (@json.False, @json.False) => true
    (@json.Number(x, ..), @json.Number(y, ..)) => (x - y).abs() < 0.0000001
    (@json.String(x), @json.String(y)) => x == y
    (@json.Array(x), @json.Array(y)) =>
      if x.length() != y.length() {
        false
      } else {
        let mut equal = true
        for i = 0; i < x.length(); i = i + 1 {
          if not(json_equals(x[i], y[i])) {
            equal = false
            break
          }
        }
        equal
      }
    (@json.Object(x), @json.Object(y)) =>
      if x.size() != y.size() {
        false
      } else {
        let mut equal = true
        x.each(fn(key, val) {
          match y.get(key) {
            Some(other_val) =>
              if not(json_equals(val, other_val)) {
                equal = false
              }
            None => equal = false
          }
        })
        equal
      }
    _ => false
  }
}

///|
fn format_path(path : String) -> String {
  if path == "" { "$" } else { "$." + path }
}

// Format validation errors for human-readable output
pub fn format_errors(errors : Array[ValidationError]) -> String {
  let mut result = "Validation failed with \{errors.length()} error(s):\n"
  for i = 0; i < errors.length(); i = i + 1 {
    let error = errors[i]
    result = result + "  - \{error.path}: \{error.message} (schema: \{error.schema_path})\n"
  }
  result
}