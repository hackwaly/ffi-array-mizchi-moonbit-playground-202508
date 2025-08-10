// JSON Schema builder and parser using built-in JSON support

pub fn parse_schema(json : Json) -> Schema? {
  match json {
    Object(obj) => build_schema_from_object(obj)
    _ => None
  }
}

fn build_schema_from_object(obj : Map[String, Json]) -> Schema? {
  // Start with an empty schema and build it up functionally
  let base_schema = Schema::new()
  
  // Build the schema by applying each property
  let schema = base_schema
  let schema = apply_meta_properties(schema, obj)
  let schema = apply_type_constraints(schema, obj)
  let schema = apply_common_validations(schema, obj)
  let schema = apply_numeric_constraints(schema, obj)
  let schema = apply_string_constraints(schema, obj)
  let schema = apply_array_constraints(schema, obj)
  let schema = apply_object_constraints(schema, obj)
  let schema = apply_logical_operations(schema, obj)
  let schema = apply_conditional_properties(schema, obj)
  let schema = apply_metadata(schema, obj)
  
  Some(schema)
}

fn apply_meta_properties(schema : Schema, obj : Map[String, Json]) -> Schema {
  let schema_uri = match obj.get("$schema") {
    Some(String(s)) => Some(s)
    _ => None
  }
  
  let id = match obj.get("$id") {
    Some(String(s)) => Some(s)
    _ => None
  }
  
  let anchor = match obj.get("$anchor") {
    Some(String(s)) => Some(s)
    _ => None
  }
  
  let ref_ = match obj.get("$ref") {
    Some(String(s)) => Some(s)
    _ => None
  }
  
  let defs = match obj.get("$defs") {
    Some(Object(defs_obj)) => {
      let def_schemas : Map[String, Schema] = Map::new()
      defs_obj.each(fn(key, val) {
        match parse_schema(val) {
          Some(def_schema) => def_schemas.set(key, def_schema)
          None => ()
        }
      })
      if def_schemas.size() > 0 { Some(def_schemas) } else { None }
    }
    _ => None
  }
  
  let comment = match obj.get("$comment") {
    Some(String(s)) => Some(s)
    _ => None
  }
  
  Schema::{
    ..schema,
    schema_uri,
    id,
    anchor,
    ref_,
    defs,
    comment
  }
}

fn apply_type_constraints(schema : Schema, obj : Map[String, Json]) -> Schema {
  let type_ = match obj.get("type") {
    Some(String(t)) => parse_schema_type(t)
    _ => None
  }
  
  let types = match obj.get("type") {
    Some(Array(type_arr)) => {
      let type_list : Array[SchemaType] = []
      for i = 0; i < type_arr.length(); i = i + 1 {
        match type_arr[i] {
          String(t) => {
            match parse_schema_type(t) {
              Some(st) => type_list.push(st)
              None => ()
            }
          }
          _ => ()
        }
      }
      if type_list.length() > 0 { Some(type_list) } else { None }
    }
    _ => None
  }
  
  Schema::{..schema, type_, types}
}

fn apply_common_validations(schema : Schema, obj : Map[String, Json]) -> Schema {
  let enum_ = match obj.get("enum") {
    Some(Array(values)) => Some(values)
    _ => None
  }
  
  let const_ = match obj.get("const") {
    Some(val) => Some(val)
    _ => None
  }
  
  Schema::{..schema, enum_, const_}
}

fn apply_numeric_constraints(schema : Schema, obj : Map[String, Json]) -> Schema {
  let minimum = match obj.get("minimum") {
    Some(Number(n, ..)) => Some(n)
    _ => None
  }
  
  let maximum = match obj.get("maximum") {
    Some(Number(n, ..)) => Some(n)
    _ => None
  }
  
  let exclusive_minimum = match obj.get("exclusiveMinimum") {
    Some(Number(n, ..)) => Some(n)
    _ => None
  }
  
  let exclusive_maximum = match obj.get("exclusiveMaximum") {
    Some(Number(n, ..)) => Some(n)
    _ => None
  }
  
  let multiple_of = match obj.get("multipleOf") {
    Some(Number(n, ..)) => Some(n)
    _ => None
  }
  
  Schema::{
    ..schema,
    minimum,
    maximum,
    exclusive_minimum,
    exclusive_maximum,
    multiple_of
  }
}

fn apply_string_constraints(schema : Schema, obj : Map[String, Json]) -> Schema {
  let min_length = match obj.get("minLength") {
    Some(Number(n, ..)) => Some(n.to_int())
    _ => None
  }
  
  let max_length = match obj.get("maxLength") {
    Some(Number(n, ..)) => Some(n.to_int())
    _ => None
  }
  
  let pattern = match obj.get("pattern") {
    Some(String(p)) => Some(p)
    _ => None
  }
  
  let format = match obj.get("format") {
    Some(String(f)) => Some(f)
    _ => None
  }
  
  let content_encoding = match obj.get("contentEncoding") {
    Some(String(e)) => Some(e)
    _ => None
  }
  
  let content_media_type = match obj.get("contentMediaType") {
    Some(String(m)) => Some(m)
    _ => None
  }
  
  let content_schema = match obj.get("contentSchema") {
    Some(content_json) => parse_schema(content_json)
    _ => None
  }
  
  Schema::{
    ..schema,
    min_length,
    max_length,
    pattern,
    format,
    content_encoding,
    content_media_type,
    content_schema
  }
}

fn apply_array_constraints(schema : Schema, obj : Map[String, Json]) -> Schema {
  let items = match obj.get("items") {
    Some(item_json) => parse_schema(item_json)
    _ => None
  }
  
  let prefix_items = match obj.get("prefixItems") {
    Some(Array(items_arr)) => {
      let prefix : Array[Schema] = []
      for i = 0; i < items_arr.length(); i = i + 1 {
        match parse_schema(items_arr[i]) {
          Some(s) => prefix.push(s)
          None => ()
        }
      }
      if prefix.length() > 0 { Some(prefix) } else { None }
    }
    _ => None
  }
  
  let contains = match obj.get("contains") {
    Some(contains_json) => parse_schema(contains_json)
    _ => None
  }
  
  let min_contains = match obj.get("minContains") {
    Some(Number(n, ..)) => Some(n.to_int())
    _ => None
  }
  
  let max_contains = match obj.get("maxContains") {
    Some(Number(n, ..)) => Some(n.to_int())
    _ => None
  }
  
  let min_items = match obj.get("minItems") {
    Some(Number(n, ..)) => Some(n.to_int())
    _ => None
  }
  
  let max_items = match obj.get("maxItems") {
    Some(Number(n, ..)) => Some(n.to_int())
    _ => None
  }
  
  let unique_items = match obj.get("uniqueItems") {
    Some(True) => Some(true)
    Some(False) => Some(false)
    _ => None
  }
  
  Schema::{
    ..schema,
    items,
    prefix_items,
    contains,
    min_contains,
    max_contains,
    min_items,
    max_items,
    unique_items
  }
}

fn apply_object_constraints(schema : Schema, obj : Map[String, Json]) -> Schema {
  let properties = match obj.get("properties") {
    Some(Object(props)) => {
      let prop_schemas : Map[String, Schema] = Map::new()
      props.each(fn(key, val) {
        match parse_schema(val) {
          Some(prop_schema) => prop_schemas.set(key, prop_schema)
          None => ()
        }
      })
      if prop_schemas.size() > 0 { Some(prop_schemas) } else { None }
    }
    _ => None
  }
  
  let required = match obj.get("required") {
    Some(Array(reqs)) => {
      let required_list : Array[String] = []
      for i = 0; i < reqs.length(); i = i + 1 {
        match reqs[i] {
          String(s) => required_list.push(s)
          _ => ()
        }
      }
      if required_list.length() > 0 { Some(required_list) } else { None }
    }
    _ => None
  }
  
  let additional_properties = match obj.get("additionalProperties") {
    Some(False) => {
      // Create a schema that rejects everything
      let reject_schema = Schema::{
        ..Schema::new(),
        type_: Some(SchemaType::Null),
        not_: Some(Schema::new())
      }
      Some(reject_schema)
    }
    Some(add_prop_json) => parse_schema(add_prop_json)
    _ => None
  }
  
  let property_names = match obj.get("propertyNames") {
    Some(prop_names_json) => parse_schema(prop_names_json)
    _ => None
  }
  
  let dependent_schemas = match obj.get("dependentSchemas") {
    Some(Object(dep_schemas)) => {
      let deps : Map[String, Schema] = Map::new()
      dep_schemas.each(fn(key, val) {
        match parse_schema(val) {
          Some(dep_schema) => deps.set(key, dep_schema)
          None => ()
        }
      })
      if deps.size() > 0 { Some(deps) } else { None }
    }
    _ => None
  }
  
  let dependent_required = match obj.get("dependentRequired") {
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
      if deps.size() > 0 { Some(deps) } else { None }
    }
    _ => None
  }
  
  let min_properties = match obj.get("minProperties") {
    Some(Number(n, ..)) => Some(n.to_int())
    _ => None
  }
  
  let max_properties = match obj.get("maxProperties") {
    Some(Number(n, ..)) => Some(n.to_int())
    _ => None
  }
  
  Schema::{
    ..schema,
    properties,
    required,
    additional_properties,
    property_names,
    dependent_schemas,
    dependent_required,
    min_properties,
    max_properties
  }
}

fn apply_logical_operations(schema : Schema, obj : Map[String, Json]) -> Schema {
  let all_of = match obj.get("allOf") {
    Some(Array(schemas)) => {
      let all : Array[Schema] = []
      for i = 0; i < schemas.length(); i = i + 1 {
        match parse_schema(schemas[i]) {
          Some(s) => all.push(s)
          None => ()
        }
      }
      if all.length() > 0 { Some(all) } else { None }
    }
    _ => None
  }
  
  let any_of = match obj.get("anyOf") {
    Some(Array(schemas)) => {
      let any : Array[Schema] = []
      for i = 0; i < schemas.length(); i = i + 1 {
        match parse_schema(schemas[i]) {
          Some(s) => any.push(s)
          None => ()
        }
      }
      if any.length() > 0 { Some(any) } else { None }
    }
    _ => None
  }
  
  let one_of = match obj.get("oneOf") {
    Some(Array(schemas)) => {
      let one : Array[Schema] = []
      for i = 0; i < schemas.length(); i = i + 1 {
        match parse_schema(schemas[i]) {
          Some(s) => one.push(s)
          None => ()
        }
      }
      if one.length() > 0 { Some(one) } else { None }
    }
    _ => None
  }
  
  let not_ = match obj.get("not") {
    Some(not_json) => parse_schema(not_json)
    _ => None
  }
  
  Schema::{
    ..schema,
    all_of,
    any_of,
    one_of,
    not_
  }
}

fn apply_conditional_properties(schema : Schema, obj : Map[String, Json]) -> Schema {
  let if_ = match obj.get("if") {
    Some(if_json) => parse_schema(if_json)
    _ => None
  }
  
  let then_ = match obj.get("then") {
    Some(then_json) => parse_schema(then_json)
    _ => None
  }
  
  let else_ = match obj.get("else") {
    Some(else_json) => parse_schema(else_json)
    _ => None
  }
  
  Schema::{..schema, if_, then_, else_}
}

fn apply_metadata(schema : Schema, obj : Map[String, Json]) -> Schema {
  let title = match obj.get("title") {
    Some(String(t)) => Some(t)
    _ => None
  }
  
  let description = match obj.get("description") {
    Some(String(d)) => Some(d)
    _ => None
  }
  
  let default = match obj.get("default") {
    Some(def) => Some(def)
    _ => None
  }
  
  let examples = match obj.get("examples") {
    Some(Array(ex)) => Some(ex)
    _ => None
  }
  
  let deprecated = match obj.get("deprecated") {
    Some(True) => Some(true)
    Some(False) => Some(false)
    _ => None
  }
  
  let read_only = match obj.get("readOnly") {
    Some(True) => Some(true)
    Some(False) => Some(false)
    _ => None
  }
  
  let write_only = match obj.get("writeOnly") {
    Some(True) => Some(true)
    Some(False) => Some(false)
    _ => None
  }
  
  Schema::{
    ..schema,
    title,
    description,
    default,
    examples,
    deprecated,
    read_only,
    write_only
  }
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