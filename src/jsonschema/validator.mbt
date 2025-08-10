// JSON Schema Validator implementation

pub struct Validator {
  schema : Schema
  mut errors : Array[ValidationError]
}

pub fn Validator::new(schema : Schema) -> Validator {
  Validator::{
    schema,
    errors: []
  }
}

pub fn validate(self : Validator, value : Json) -> ValidationResult {
  self.errors = []
  self.validate_value(value, self.schema, "", "#")
  
  if self.errors.length() > 0 {
    Err(self.errors)
  } else {
    Ok
  }
}

fn validate_value(self : Validator, value : Json, schema : Schema, path : String, schema_path : String) -> Unit {
  // Type validation
  match schema.type_ {
    Some(expected_type) => {
      if not(check_type(value, expected_type)) {
        self.add_error(path, "Type mismatch: expected " + expected_type.to_string(), schema_path + "/type")
      }
    }
    None => ()
  }
  
  // Multiple types validation
  match schema.types {
    Some(types) => {
      let mut valid = false
      for i = 0; i < types.length(); i = i + 1 {
        if check_type(value, types[i]) {
          valid = true
          break
        }
      }
      if not(valid) {
        self.add_error(path, "Value does not match any of the allowed types", schema_path + "/types")
      }
    }
    None => ()
  }
  
  // Enum validation
  match schema.enum_ {
    Some(allowed_values) => {
      let mut found = false
      for i = 0; i < allowed_values.length(); i = i + 1 {
        if self.json_equals(value, allowed_values[i]) {
          found = true
          break
        }
      }
      if not(found) {
        self.add_error(path, "Value is not in the enumeration", schema_path + "/enum")
      }
    }
    None => ()
  }
  
  // Const validation
  match schema.const_ {
    Some(const_value) => {
      if not(self.json_equals(value, const_value)) {
        self.add_error(path, "Value does not match const", schema_path + "/const")
      }
    }
    None => ()
  }
  
  // Type-specific validations
  match value {
    Number(n, ..) => self.validate_number(n, schema, path, schema_path)
    String(s) => self.validate_string(s, schema, path, schema_path)
    Array(arr) => self.validate_array(arr, schema, path, schema_path)
    Object(obj) => self.validate_object(obj, schema, path, schema_path)
    _ => ()
  }
  
  // Logical validations
  self.validate_logical(value, schema, path, schema_path)
}

fn validate_number(self : Validator, value : Double, schema : Schema, path : String, schema_path : String) -> Unit {
  // Minimum
  match schema.minimum {
    Some(min) => {
      if value < min {
        self.add_error(path, "Value \{value} is less than minimum \{min}", schema_path + "/minimum")
      }
    }
    None => ()
  }
  
  // Maximum
  match schema.maximum {
    Some(max) => {
      if value > max {
        self.add_error(path, "Value \{value} is greater than maximum \{max}", schema_path + "/maximum")
      }
    }
    None => ()
  }
  
  // Exclusive minimum
  match schema.exclusive_minimum {
    Some(min) => {
      if value <= min {
        self.add_error(path, "Value \{value} is not greater than exclusive minimum \{min}", schema_path + "/exclusiveMinimum")
      }
    }
    None => ()
  }
  
  // Exclusive maximum
  match schema.exclusive_maximum {
    Some(max) => {
      if value >= max {
        self.add_error(path, "Value \{value} is not less than exclusive maximum \{max}", schema_path + "/exclusiveMaximum")
      }
    }
    None => ()
  }
  
  // Multiple of
  match schema.multiple_of {
    Some(divisor) => {
      if divisor > 0.0 {
        let remainder = value % divisor
        if remainder.abs() > 0.0000001 {
          self.add_error(path, "Value \{value} is not a multiple of \{divisor}", schema_path + "/multipleOf")
        }
      }
    }
    None => ()
  }
}

fn validate_string(self : Validator, value : String, schema : Schema, path : String, schema_path : String) -> Unit {
  let len = value.length()
  
  // Min length
  match schema.min_length {
    Some(min) => {
      if len < min {
        self.add_error(path, "String length \{len} is less than minimum \{min}", schema_path + "/minLength")
      }
    }
    None => ()
  }
  
  // Max length
  match schema.max_length {
    Some(max) => {
      if len > max {
        self.add_error(path, "String length \{len} is greater than maximum \{max}", schema_path + "/maxLength")
      }
    }
    None => ()
  }
  
  // Pattern validation would require regex support
  // Format validation would require format-specific checks
}

fn validate_array(self : Validator, value : Array[Json], schema : Schema, path : String, schema_path : String) -> Unit {
  let len = value.length()
  
  // Min items
  match schema.min_items {
    Some(min) => {
      if len < min {
        self.add_error(path, "Array length \{len} is less than minimum \{min}", schema_path + "/minItems")
      }
    }
    None => ()
  }
  
  // Max items
  match schema.max_items {
    Some(max) => {
      if len > max {
        self.add_error(path, "Array length \{len} is greater than maximum \{max}", schema_path + "/maxItems")
      }
    }
    None => ()
  }
  
  // Unique items
  match schema.unique_items {
    Some(unique) => {
      if unique {
        for i = 0; i < len - 1; i = i + 1 {
          for j = i + 1; j < len; j = j + 1 {
            if self.json_equals(value[i], value[j]) {
              self.add_error(path, "Array contains duplicate items at indices \{i} and \{j}", schema_path + "/uniqueItems")
            }
          }
        }
      }
    }
    None => ()
  }
  
  // Prefix items validation (2020-12)
  match schema.prefix_items {
    Some(prefix_schemas) => {
      let prefix_len = prefix_schemas.length()
      for i = 0; i < len && i < prefix_len; i = i + 1 {
        let item_path = path + "[\{i}]"
        self.validate_value(value[i], prefix_schemas[i], item_path, schema_path + "/prefixItems[\{i}]")
      }
      // Items beyond prefix are validated by items schema
      match schema.items {
        Some(item_schema) => {
          for i = prefix_len; i < len; i = i + 1 {
            let item_path = path + "[\{i}]"
            self.validate_value(value[i], item_schema, item_path, schema_path + "/items")
          }
        }
        None => ()
      }
    }
    None => {
      // Items validation (no prefix)
      match schema.items {
        Some(item_schema) => {
          for i = 0; i < len; i = i + 1 {
            let item_path = path + "[\{i}]"
            self.validate_value(value[i], item_schema, item_path, schema_path + "/items")
          }
        }
        None => ()
      }
    }
  }
  
  // Contains validation
  match schema.contains {
    Some(contains_schema) => {
      let mut contains_count = 0
      for i = 0; i < len; i = i + 1 {
        let temp_validator = Validator::new(contains_schema)
        let result = temp_validator.validate(value[i])
        match result {
          Ok => contains_count = contains_count + 1
          Err(_) => ()
        }
      }
      
      // Check minContains
      match schema.min_contains {
        Some(min) => {
          if contains_count < min {
            self.add_error(path, "Array contains only \{contains_count} matching items, less than minimum \{min}", schema_path + "/minContains")
          }
        }
        None => {
          // Default minContains is 1 if contains is present
          if contains_count < 1 {
            self.add_error(path, "Array does not contain any item matching the schema", schema_path + "/contains")
          }
        }
      }
      
      // Check maxContains
      match schema.max_contains {
        Some(max) => {
          if contains_count > max {
            self.add_error(path, "Array contains \{contains_count} matching items, more than maximum \{max}", schema_path + "/maxContains")
          }
        }
        None => ()
      }
    }
    None => ()
  }
}

fn validate_object(self : Validator, value : Map[String, Json], schema : Schema, path : String, schema_path : String) -> Unit {
  // Required properties
  match schema.required {
    Some(required_props) => {
      for i = 0; i < required_props.length(); i = i + 1 {
        let prop = required_props[i]
        if not(value.contains(prop)) {
          self.add_error(path, "Required property '\{prop}' is missing", schema_path + "/required")
        }
      }
    }
    None => ()
  }
  
  // Properties validation
  match schema.properties {
    Some(props) => {
      props.each(fn(prop_name, prop_schema) {
        match value.get(prop_name) {
          Some(prop_value) => {
            let prop_path = if path == "" { prop_name } else { path + "." + prop_name }
            self.validate_value(prop_value, prop_schema, prop_path, schema_path + "/properties/" + prop_name)
          }
          None => ()
        }
      })
    }
    None => ()
  }
  
  // Additional properties
  match schema.additional_properties {
    Some(add_schema) => {
      value.each(fn(key, val) {
        let is_defined = match schema.properties {
          Some(props) => props.contains(key)
          None => false
        }
        
        if not(is_defined) {
          let prop_path = if path == "" { key } else { path + "." + key }
          self.validate_value(val, add_schema, prop_path, schema_path + "/additionalProperties")
        }
      })
    }
    None => ()
  }
  
  // Min/Max properties
  let prop_count = value.size()
  
  match schema.min_properties {
    Some(min) => {
      if prop_count < min {
        self.add_error(path, "Object has \{prop_count} properties, less than minimum \{min}", schema_path + "/minProperties")
      }
    }
    None => ()
  }
  
  match schema.max_properties {
    Some(max) => {
      if prop_count > max {
        self.add_error(path, "Object has \{prop_count} properties, more than maximum \{max}", schema_path + "/maxProperties")
      }
    }
    None => ()
  }
}

fn validate_logical(self : Validator, value : Json, schema : Schema, path : String, schema_path : String) -> Unit {
  // allOf
  match schema.all_of {
    Some(schemas) => {
      for i = 0; i < schemas.length(); i = i + 1 {
        self.validate_value(value, schemas[i], path, schema_path + "/allOf[\{i}]")
      }
    }
    None => ()
  }
  
  // anyOf
  match schema.any_of {
    Some(schemas) => {
      let _initial_errors = self.errors.length()
      let mut any_valid = false
      
      for i = 0; i < schemas.length(); i = i + 1 {
        let temp_validator = Validator::new(schemas[i])
        let result = temp_validator.validate(value)
        match result {
          Ok => {
            any_valid = true
            break
          }
          Err(_) => ()
        }
      }
      
      if not(any_valid) {
        self.add_error(path, "Value does not match any schema in anyOf", schema_path + "/anyOf")
      }
    }
    None => ()
  }
  
  // oneOf
  match schema.one_of {
    Some(schemas) => {
      let mut valid_count = 0
      
      for i = 0; i < schemas.length(); i = i + 1 {
        let temp_validator = Validator::new(schemas[i])
        let result = temp_validator.validate(value)
        match result {
          Ok => valid_count = valid_count + 1
          Err(_) => ()
        }
      }
      
      if valid_count == 0 {
        self.add_error(path, "Value does not match any schema in oneOf", schema_path + "/oneOf")
      } else if valid_count > 1 {
        self.add_error(path, "Value matches multiple schemas in oneOf", schema_path + "/oneOf")
      }
    }
    None => ()
  }
  
  // not
  match schema.not_ {
    Some(not_schema) => {
      let temp_validator = Validator::new(not_schema)
      let result = temp_validator.validate(value)
      match result {
        Ok => self.add_error(path, "Value should not match the schema in 'not'", schema_path + "/not")
        Err(_) => ()
      }
    }
    None => ()
  }
}

fn check_type(value : Json, expected : SchemaType) -> Bool {
  match (value, expected) {
    (Null, Null) => true
    (True, Boolean) => true
    (False, Boolean) => true
    (Number(_, ..), Number) => true
    (Number(n, ..), Integer) => n.floor() == n
    (String(_), String) => true
    (Array(_), Array) => true
    (Object(_), Object) => true
    _ => false
  }
}

fn json_equals(self : Validator, a : Json, b : Json) -> Bool {
  match (a, b) {
    (Null, Null) => true
    (True, True) => true
    (False, False) => true
    (Number(x, ..), Number(y, ..)) => (x - y).abs() < 0.0000001
    (String(x), String(y)) => x == y
    (Array(x), Array(y)) => {
      if x.length() != y.length() {
        false
      } else {
        let mut equal = true
        for i = 0; i < x.length(); i = i + 1 {
          if not(self.json_equals(x[i], y[i])) {
            equal = false
            break
          }
        }
        equal
      }
    }
    (Object(x), Object(y)) => {
      if x.size() != y.size() {
        false
      } else {
        let mut equal = true
        x.each(fn(key, val) {
          match y.get(key) {
            Some(other_val) => {
              if not(self.json_equals(val, other_val)) {
                equal = false
              }
            }
            None => equal = false
          }
        })
        equal
      }
    }
    _ => false
  }
}

fn add_error(self : Validator, path : String, message : String, schema_path : String) -> Unit {
  let error_path = if path == "" { "$" } else { "$." + path }
  self.errors.push(ValidationError::new(error_path, message, schema_path))
}