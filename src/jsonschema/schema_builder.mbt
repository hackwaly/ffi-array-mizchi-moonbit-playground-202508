// JSON Schema builder and parser using built-in JSON support

pub fn parse_schema(json : Json) -> Schema? {
  match json {
    Object(obj) => build_schema_from_object(obj)
    _ => None
  }
}

fn build_schema_from_object(obj : Map[String, Json]) -> Schema? {
  let schema = Schema::new()
  
  // Meta-schema properties
  match obj.get("$schema") {
    Some(String(s)) => schema.schema_uri = Some(s)
    _ => ()
  }
  
  match obj.get("$id") {
    Some(String(s)) => schema.id = Some(s)
    _ => ()
  }
  
  match obj.get("$anchor") {
    Some(String(s)) => schema.anchor = Some(s)
    _ => ()
  }
  
  match obj.get("$ref") {
    Some(String(s)) => schema.ref_ = Some(s)
    _ => ()
  }
  
  match obj.get("$defs") {
    Some(Object(defs)) => {
      let def_schemas : Map[String, Schema] = Map::new()
      defs.each(fn(key, val) {
        match parse_schema(val) {
          Some(def_schema) => def_schemas.set(key, def_schema)
          None => ()
        }
      })
      if def_schemas.size() > 0 {
        schema.defs = Some(def_schemas)
      }
    }
    _ => ()
  }
  
  match obj.get("$comment") {
    Some(String(s)) => schema.comment = Some(s)
    _ => ()
  }
  
  // Type
  match obj.get("type") {
    Some(String(t)) => schema.type_ = parse_schema_type(t)
    Some(Array(types)) => {
      let type_array : Array[SchemaType] = []
      for i = 0; i < types.length(); i = i + 1 {
        match types[i] {
          String(t) => {
            match parse_schema_type(t) {
              Some(st) => type_array.push(st)
              None => ()
            }
          }
          _ => ()
        }
      }
      if type_array.length() > 0 {
        schema.types = Some(type_array)
      }
    }
    _ => ()
  }
  
  // Enum
  match obj.get("enum") {
    Some(Array(values)) => schema.enum_ = Some(values)
    _ => ()
  }
  
  // Const
  match obj.get("const") {
    Some(val) => schema.const_ = Some(val)
    _ => ()
  }
  
  // Numeric constraints
  match obj.get("minimum") {
    Some(Number(n, ..)) => schema.minimum = Some(n)
    _ => ()
  }
  
  match obj.get("maximum") {
    Some(Number(n, ..)) => schema.maximum = Some(n)
    _ => ()
  }
  
  match obj.get("exclusiveMinimum") {
    Some(Number(n, ..)) => schema.exclusive_minimum = Some(n)
    _ => ()
  }
  
  match obj.get("exclusiveMaximum") {
    Some(Number(n, ..)) => schema.exclusive_maximum = Some(n)
    _ => ()
  }
  
  match obj.get("multipleOf") {
    Some(Number(n, ..)) => schema.multiple_of = Some(n)
    _ => ()
  }
  
  // String constraints
  match obj.get("minLength") {
    Some(Number(n, ..)) => schema.min_length = Some(n.to_int())
    _ => ()
  }
  
  match obj.get("maxLength") {
    Some(Number(n, ..)) => schema.max_length = Some(n.to_int())
    _ => ()
  }
  
  match obj.get("pattern") {
    Some(String(p)) => schema.pattern = Some(p)
    _ => ()
  }
  
  match obj.get("format") {
    Some(String(f)) => schema.format = Some(f)
    _ => ()
  }
  
  match obj.get("contentEncoding") {
    Some(String(e)) => schema.content_encoding = Some(e)
    _ => ()
  }
  
  match obj.get("contentMediaType") {
    Some(String(m)) => schema.content_media_type = Some(m)
    _ => ()
  }
  
  match obj.get("contentSchema") {
    Some(content_json) => {
      match parse_schema(content_json) {
        Some(content_schema) => schema.content_schema = Some(content_schema)
        None => ()
      }
    }
    _ => ()
  }
  
  // Array constraints
  match obj.get("items") {
    Some(item_json) => {
      match parse_schema(item_json) {
        Some(item_schema) => schema.items = Some(item_schema)
        None => ()
      }
    }
    _ => ()
  }
  
  match obj.get("prefixItems") {
    Some(Array(items)) => {
      let prefix : Array[Schema] = []
      for i = 0; i < items.length(); i = i + 1 {
        match parse_schema(items[i]) {
          Some(s) => prefix.push(s)
          None => ()
        }
      }
      if prefix.length() > 0 {
        schema.prefix_items = Some(prefix)
      }
    }
    _ => ()
  }
  
  match obj.get("contains") {
    Some(contains_json) => {
      match parse_schema(contains_json) {
        Some(contains_schema) => schema.contains = Some(contains_schema)
        None => ()
      }
    }
    _ => ()
  }
  
  match obj.get("minContains") {
    Some(Number(n, ..)) => schema.min_contains = Some(n.to_int())
    _ => ()
  }
  
  match obj.get("maxContains") {
    Some(Number(n, ..)) => schema.max_contains = Some(n.to_int())
    _ => ()
  }
  
  match obj.get("minItems") {
    Some(Number(n, ..)) => schema.min_items = Some(n.to_int())
    _ => ()
  }
  
  match obj.get("maxItems") {
    Some(Number(n, ..)) => schema.max_items = Some(n.to_int())
    _ => ()
  }
  
  match obj.get("uniqueItems") {
    Some(True) => schema.unique_items = Some(true)
    Some(False) => schema.unique_items = Some(false)
    _ => ()
  }
  
  // Object constraints
  match obj.get("properties") {
    Some(Object(props)) => {
      let prop_schemas : Map[String, Schema] = Map::new()
      props.each(fn(key, val) {
        match parse_schema(val) {
          Some(prop_schema) => prop_schemas.set(key, prop_schema)
          None => ()
        }
      })
      if prop_schemas.size() > 0 {
        schema.properties = Some(prop_schemas)
      }
    }
    _ => ()
  }
  
  match obj.get("required") {
    Some(Array(reqs)) => {
      let required : Array[String] = []
      for i = 0; i < reqs.length(); i = i + 1 {
        match reqs[i] {
          String(s) => required.push(s)
          _ => ()
        }
      }
      if required.length() > 0 {
        schema.required = Some(required)
      }
    }
    _ => ()
  }
  
  match obj.get("propertyNames") {
    Some(prop_names_json) => {
      match parse_schema(prop_names_json) {
        Some(prop_names_schema) => schema.property_names = Some(prop_names_schema)
        None => ()
      }
    }
    _ => ()
  }
  
  match obj.get("dependentSchemas") {
    Some(Object(dep_schemas)) => {
      let deps : Map[String, Schema] = Map::new()
      dep_schemas.each(fn(key, val) {
        match parse_schema(val) {
          Some(dep_schema) => deps.set(key, dep_schema)
          None => ()
        }
      })
      if deps.size() > 0 {
        schema.dependent_schemas = Some(deps)
      }
    }
    _ => ()
  }
  
  match obj.get("dependentRequired") {
    Some(Object(dep_reqs)) => {
      let deps : Map[String, Array[String]] = Map::new()
      dep_reqs.each(fn(key, val) {
        match val {
          Array(reqs) => {
            let req_array : Array[String] = []
            for i = 0; i < reqs.length(); i = i + 1 {
              match reqs[i] {
                String(s) => req_array.push(s)
                _ => ()
              }
            }
            if req_array.length() > 0 {
              deps.set(key, req_array)
            }
          }
          _ => ()
        }
      })
      if deps.size() > 0 {
        schema.dependent_required = Some(deps)
      }
    }
    _ => ()
  }
  
  match obj.get("additionalProperties") {
    Some(False) => {
      // Create a schema that rejects everything
      let reject_schema = Schema::new()
      reject_schema.type_ = Some(SchemaType::Null)
      reject_schema.not_ = Some(Schema::new())
      schema.additional_properties = Some(reject_schema)
    }
    Some(add_prop_json) => {
      match parse_schema(add_prop_json) {
        Some(add_schema) => schema.additional_properties = Some(add_schema)
        None => ()
      }
    }
    _ => ()
  }
  
  match obj.get("minProperties") {
    Some(Number(n, ..)) => schema.min_properties = Some(n.to_int())
    _ => ()
  }
  
  match obj.get("maxProperties") {
    Some(Number(n, ..)) => schema.max_properties = Some(n.to_int())
    _ => ()
  }
  
  // Logical operators
  match obj.get("allOf") {
    Some(Array(schemas)) => {
      let all : Array[Schema] = []
      for i = 0; i < schemas.length(); i = i + 1 {
        match parse_schema(schemas[i]) {
          Some(s) => all.push(s)
          None => ()
        }
      }
      if all.length() > 0 {
        schema.all_of = Some(all)
      }
    }
    _ => ()
  }
  
  match obj.get("anyOf") {
    Some(Array(schemas)) => {
      let any : Array[Schema] = []
      for i = 0; i < schemas.length(); i = i + 1 {
        match parse_schema(schemas[i]) {
          Some(s) => any.push(s)
          None => ()
        }
      }
      if any.length() > 0 {
        schema.any_of = Some(any)
      }
    }
    _ => ()
  }
  
  match obj.get("oneOf") {
    Some(Array(schemas)) => {
      let one : Array[Schema] = []
      for i = 0; i < schemas.length(); i = i + 1 {
        match parse_schema(schemas[i]) {
          Some(s) => one.push(s)
          None => ()
        }
      }
      if one.length() > 0 {
        schema.one_of = Some(one)
      }
    }
    _ => ()
  }
  
  match obj.get("not") {
    Some(not_json) => {
      match parse_schema(not_json) {
        Some(not_schema) => schema.not_ = Some(not_schema)
        None => ()
      }
    }
    _ => ()
  }
  
  // Metadata
  match obj.get("title") {
    Some(String(t)) => schema.title = Some(t)
    _ => ()
  }
  
  match obj.get("description") {
    Some(String(d)) => schema.description = Some(d)
    _ => ()
  }
  
  match obj.get("default") {
    Some(def) => schema.default = Some(def)
    _ => ()
  }
  
  match obj.get("examples") {
    Some(Array(ex)) => schema.examples = Some(ex)
    _ => ()
  }
  
  match obj.get("deprecated") {
    Some(True) => schema.deprecated = Some(true)
    Some(False) => schema.deprecated = Some(false)
    _ => ()
  }
  
  match obj.get("readOnly") {
    Some(True) => schema.read_only = Some(true)
    Some(False) => schema.read_only = Some(false)
    _ => ()
  }
  
  match obj.get("writeOnly") {
    Some(True) => schema.write_only = Some(true)
    Some(False) => schema.write_only = Some(false)
    _ => ()
  }
  
  Some(schema)
}

fn parse_schema_type(type_str : String) -> SchemaType? {
  match type_str {
    "null" => Some(Null)
    "boolean" => Some(Boolean)
    "number" => Some(Number)
    "integer" => Some(Integer)
    "string" => Some(String)
    "array" => Some(Array)
    "object" => Some(Object)
    _ => None
  }
}