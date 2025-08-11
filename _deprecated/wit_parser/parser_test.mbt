// Tests for WIT parser

test "parse simple interface" {
  let input = """
interface hello {
  say-hello: func(name: string) -> string;
}
"""
  
  let result = parse_wit(input)
  inspect!(result.is_ok(), content="true")
  
  let doc = result.unwrap()
  inspect!(doc.items.length(), content="1")
  
  match doc.items[0] {
    TopLevelItem::Interface(iface) => {
      inspect!(iface.name, content="hello")
      inspect!(iface.items.length(), content="1")
      
      match iface.items[0] {
        InterfaceItem::Function(func) => {
          inspect!(func.name, content="say-hello")
          inspect!(func.params.length(), content="1")
          inspect!(func.params[0].name, content="name")
          match func.params[0].typ {
            Type::String => inspect!(true, content="true")
            _ => inspect!(false, content="true")
          }
        }
        _ => inspect!(false, content="true")
      }
    }
    _ => inspect!(false, content="true")
  }
}

test "parse interface with types" {
  let input = """
interface types {
  type person = record {
    name: string,
    age: u32,
  };
  
  type status = enum {
    active,
    inactive,
  };
  
  get-person: func(id: u64) -> person;
}
"""
  
  let result = parse_wit(input)
  inspect!(result.is_ok(), content="true")
  
  let doc = result.unwrap()
  match doc.items[0] {
    TopLevelItem::Interface(iface) => {
      inspect!(iface.name, content="types")
      inspect!(iface.items.length(), content="3")
      
      // Check record type
      match iface.items[0] {
        InterfaceItem::Type(type_def) => {
          inspect!(type_def.name, content="person")
          match type_def.def {
            TypeDefKind::Record(record) => {
              inspect!(record.fields.length(), content="2")
              inspect!(record.fields[0].name, content="name")
              inspect!(record.fields[1].name, content="age")
            }
            _ => inspect!(false, content="true")
          }
        }
        _ => inspect!(false, content="true")
      }
      
      // Check enum type
      match iface.items[1] {
        InterfaceItem::Type(type_def) => {
          inspect!(type_def.name, content="status")
          match type_def.def {
            TypeDefKind::Enum(enum_) => {
              inspect!(enum_.cases.length(), content="2")
              inspect!(enum_.cases[0], content="active")
              inspect!(enum_.cases[1], content="inactive")
            }
            _ => inspect!(false, content="true")
          }
        }
        _ => inspect!(false, content="true")
      }
    }
    _ => inspect!(false, content="true")
  }
}

test "parse world with imports and exports" {
  let input = """
world my-world {
  import print: func(msg: string);
  export run: func() -> result<string, string>;
}
"""
  
  let result = parse_wit(input)
  inspect!(result.is_ok(), content="true")
  
  let doc = result.unwrap()
  match doc.items[0] {
    TopLevelItem::World(world) => {
      inspect!(world.name, content="my-world")
      inspect!(world.items.length(), content="2")
      
      // Check import
      match world.items[0] {
        WorldItem::Import(import) => {
          inspect!(import.name, content="print")
          match import.kind {
            ImportKind::Function(func) => {
              inspect!(func.params.length(), content="1")
              inspect!(func.params[0].name, content="msg")
            }
            _ => inspect!(false, content="true")
          }
        }
        _ => inspect!(false, content="true")
      }
      
      // Check export
      match world.items[1] {
        WorldItem::Export(export) => {
          inspect!(export.name, content="run")
          match export.kind {
            ExportKind::Function(func) => {
              inspect!(func.params.length(), content="0")
              match func.results {
                FunctionResult::Single(Type::Result { ok, err }) => {
                  inspect!(ok.is_some(), content="true")
                  inspect!(err.is_some(), content="true")
                }
                _ => inspect!(false, content="true")
              }
            }
            _ => inspect!(false, content="true")
          }
        }
        _ => inspect!(false, content="true")
      }
    }
    _ => inspect!(false, content="true")
  }
}

test "parse variant type" {
  let input = """
interface variants {
  type result = variant {
    ok(string),
    err(u32),
  };
}
"""
  
  let result = parse_wit(input)
  inspect!(result.is_ok(), content="true")
  
  let doc = result.unwrap()
  match doc.items[0] {
    TopLevelItem::Interface(iface) => {
      match iface.items[0] {
        InterfaceItem::Type(type_def) => {
          inspect!(type_def.name, content="result")
          match type_def.def {
            TypeDefKind::Variant(variant) => {
              inspect!(variant.cases.length(), content="2")
              inspect!(variant.cases[0].name, content="ok")
              inspect!(variant.cases[0].typ.is_some(), content="true")
              inspect!(variant.cases[1].name, content="err")
              inspect!(variant.cases[1].typ.is_some(), content="true")
            }
            _ => inspect!(false, content="true")
          }
        }
        _ => inspect!(false, content="true")
      }
    }
    _ => inspect!(false, content="true")
  }
}

test "parse flags type" {
  let input = """
interface flags-test {
  type permissions = flags {
    read,
    write,
    execute,
  };
}
"""
  
  let result = parse_wit(input)
  inspect!(result.is_ok(), content="true")
  
  let doc = result.unwrap()
  match doc.items[0] {
    TopLevelItem::Interface(iface) => {
      match iface.items[0] {
        InterfaceItem::Type(type_def) => {
          inspect!(type_def.name, content="permissions")
          match type_def.def {
            TypeDefKind::Flags(flags) => {
              inspect!(flags.flags.length(), content="3")
              inspect!(flags.flags[0], content="read")
              inspect!(flags.flags[1], content="write")
              inspect!(flags.flags[2], content="execute")
            }
            _ => inspect!(false, content="true")
          }
        }
        _ => inspect!(false, content="true")
      }
    }
    _ => inspect!(false, content="true")
  }
}

test "parse resource type" {
  let input = """
interface resources {
  resource file {
    constructor(path: string);
    read: method() -> list<u8>;
    write: method(data: list<u8>);
    close: static();
  }
}
"""
  
  let result = parse_wit(input)
  inspect!(result.is_ok(), content="true")
  
  let doc = result.unwrap()
  match doc.items[0] {
    TopLevelItem::Interface(iface) => {
      match iface.items[0] {
        InterfaceItem::Type(type_def) => {
          inspect!(type_def.name, content="file")
          match type_def.def {
            TypeDefKind::Resource(resource) => {
              inspect!(resource.methods.length(), content="4")
              
              // Check constructor
              match resource.methods[0].kind {
                MethodKind::Constructor(params) => {
                  inspect!(params.length(), content="1")
                  inspect!(params[0].name, content="path")
                }
                _ => inspect!(false, content="true")
              }
              
              // Check methods
              inspect!(resource.methods[1].name, content="read")
              inspect!(resource.methods[2].name, content="write")
              inspect!(resource.methods[3].name, content="close")
            }
            _ => inspect!(false, content="true")
          }
        }
        _ => inspect!(false, content="true")
      }
    }
    _ => inspect!(false, content="true")
  }
}

test "parse complex types" {
  let input = """
interface complex {
  type data = list<tuple<string, u32>>;
  type maybe-string = option<string>;
  process: func(input: data) -> result<maybe-string, string>;
}
"""
  
  let result = parse_wit(input)
  inspect!(result.is_ok(), content="true")
  
  let doc = result.unwrap()
  match doc.items[0] {
    TopLevelItem::Interface(iface) => {
      inspect!(iface.items.length(), content="3")
      
      // Check list<tuple<string, u32>>
      match iface.items[0] {
        InterfaceItem::Type(type_def) => {
          inspect!(type_def.name, content="data")
          match type_def.def {
            TypeDefKind::Alias(Type::List(inner)) => {
              match inner {
                Type::Tuple(types) => {
                  inspect!(types.length(), content="2")
                }
                _ => inspect!(false, content="true")
              }
            }
            _ => inspect!(false, content="true")
          }
        }
        _ => inspect!(false, content="true")
      }
      
      // Check option<string>
      match iface.items[1] {
        InterfaceItem::Type(type_def) => {
          inspect!(type_def.name, content="maybe-string")
          match type_def.def {
            TypeDefKind::Alias(Type::Option(inner)) => {
              match inner {
                Type::String => inspect!(true, content="true")
                _ => inspect!(false, content="true")
              }
            }
            _ => inspect!(false, content="true")
          }
        }
        _ => inspect!(false, content="true")
      }
    }
    _ => inspect!(false, content="true")
  }
}

test "parse use statements" {
  let input = """
use wasi:io/streams.{input-stream, output-stream};

interface io {
  use wasi:io/poll.*;
  
  read: func(stream: input-stream) -> list<u8>;
}
"""
  
  let result = parse_wit(input)
  inspect!(result.is_ok(), content="true")
  
  let doc = result.unwrap()
  inspect!(doc.items.length(), content="2")
  
  // Check top-level use
  match doc.items[0] {
    TopLevelItem::Use(use_item) => {
      inspect!(use_item.path, content="wasi:io/streams")
      match use_item.items[0] {
        UseItemSpec::Named(names) => {
          inspect!(names.length(), content="2")
          inspect!(names[0], content="input-stream")
          inspect!(names[1], content="output-stream")
        }
        _ => inspect!(false, content="true")
      }
    }
    _ => inspect!(false, content="true")
  }
  
  // Check interface use
  match doc.items[1] {
    TopLevelItem::Interface(iface) => {
      match iface.items[0] {
        InterfaceItem::Use(use_item) => {
          inspect!(use_item.path, content="wasi:io/poll")
          match use_item.items[0] {
            UseItemSpec::All => inspect!(true, content="true")
            _ => inspect!(false, content="true")
          }
        }
        _ => inspect!(false, content="true")
      }
    }
    _ => inspect!(false, content="true")
  }
}