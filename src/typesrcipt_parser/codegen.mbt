// FFI code generation from TypeScript declarations

// TypeScript型をMoonBit型に変換

///|
pub fn type_to_moonbit(typ : Type) -> String {
  match typ {
    String => "String"
    Number => "Double"
    Boolean => "Bool"
    Void => "Unit"
    Any => "Any"
    Unknown => "Any"
    Never => "Never"
    Null => "Null"
    Undefined => "Unit"
    Array(element_type) => "Array[" + type_to_moonbit(element_type) + "]"
    TypeReference(name, type_args) =>
      if name == "Promise" && type_args.length() > 0 {
        // Promise<T> はそのまま Promise[T] に写像
        "Promise[" + type_to_moonbit(type_args[0]) + "]"
      } else {
        // mbt.* プレフィックス対応は「その他」よりも前に行う
        // - mbt.String -> String
        // - mbt.Int -> Int
        // - mbt.Float -> Double
        // - mbt.Void -> Unit
        // - 上記以外は "mbt." を外した末尾名にフォールバック（例: mbt.Custom -> Custom）
        let is_mbt = name.length() > 4 &&
          name[0] == 'm' &&
          name[1] == 'b' &&
          name[2] == 't' &&
          name[3] == '.'
        if is_mbt {
          // 既知の4種は厳密マップ
          let base = if name == "mbt.String" {
            "String"
          } else if name == "mbt.Int" {
            "Int"
          } else if name == "mbt.Float" {
            "Double"
          } else if name == "mbt.Void" {
            "Unit"
          } else {
            // "mbt." を取り除いた残りを tail として使用
            let tail_builder = StringBuilder::new()
            let n = name.length()
            let mut i = 4
            while i < n {
              let ch = Int::to_char(name[i]) |> Option::unwrap_or('?')
              tail_builder.write_char(ch)
              i = i + 1
            }
            tail_builder.to_string()
          }
          if type_args.length() > 0 {
            let args = type_args.map(fn(t) { type_to_moonbit(t) }).join(", ")
            base + "[" + args + "]"
          } else {
            base
          }
        } else if type_args.length() > 0 {
          let args = type_args.map(fn(t) { type_to_moonbit(t) }).join(", ")
          name + "[" + args + "]"
        } else {
          // 既存のマッピングテーブル
          match name {
            "HTMLElement" => "JSValue"
            "Element" => "JSValue"
            "Document" => "JSValue"
            "Window" => "JSValue"
            "Event" => "JSValue"
            "MouseEvent" => "JSValue"
            "KeyboardEvent" => "JSValue"
            _ => name
          }
        }
      }
    Union(_) =>
      // Union型は簡略化してAnyにする（実際にはより複雑な処理が必要）
      "Any"
    Intersection(_) =>
      // Intersection型も簡略化
      "Any"
    Function(func_type) => {
      let params = func_type.params
        .map(fn(p) { type_to_moonbit(p.type_) })
        .join(", ")
      "(" + params + ") -> " + type_to_moonbit(func_type.return_type)
    }
    Object(props) => {
      // オブジェクト型はレコードリテラル風に出力: { x: Int; y: Int }
      // まず "key: Type" の配列を作り、キー順で簡易ソートしてから連結する
      let parts : Array[String] = []
      props.each(fn(k, v) {
        let sb = StringBuilder::new()
        sb.write_string(k)
        sb.write_string(": ")
        sb.write_string(type_to_moonbit(v))
        parts.push(sb.to_string())
      })
      // 簡易ソート（小規模前提）
      let n = parts.length()
      for i = 0; i < n; i = i + 1 {
        for j = i + 1; j < n; j = j + 1 {
          if parts[j] < parts[i] {
            let tmp = parts[i]
            parts[i] = parts[j]
            parts[j] = tmp
          }
        }
      }
      let b = StringBuilder::new()
      b.write_string("{ ")
      for i = 0; i < n; i = i + 1 {
        if i > 0 {
          b.write_string("; ")
        }
        b.write_string(parts[i])
      }
      b.write_string(" }")
      b.to_string()
    }
    Literal(_) => "Any"
    Tuple(types) => {
      let elements = types.map(fn(t) { type_to_moonbit(t) }).join(", ")
      "(" + elements + ")"
    }
    Optional(inner_type) => "Option[" + type_to_moonbit(inner_type) + "]"
    Readonly(inner_type) => type_to_moonbit(inner_type)
  }
}

// パラメータをMoonBit形式に変換

///|
pub fn parameter_to_moonbit(param : Parameter) -> String {
  let type_str = type_to_moonbit(param.type_)
  if param.optional {
    param.name + " : Option[" + type_str + "]"
  } else if param.rest {
    param.name + " : Array[" + type_str + "]"
  } else {
    param.name + " : " + type_str
  }
}

// 関数宣言からFFIバインディングを生成

///|
pub fn generate_function_binding(func : FunctionDeclaration) -> String {
  let result = StringBuilder::new()

  // extern宣言
  result.write_string("extern \"js\" ")
  result.write_string("fn ")
  result.write_string(func.name)
  result.write_string("(")

  // パラメータ
  let params = func.params.map(fn(p) { parameter_to_moonbit(p) })
  result.write_string(params.join(", "))
  result.write_string(") -> ")
  result.write_string(type_to_moonbit(func.return_type))
  result.write_string(" = #|")

  // JavaScript側の実装
  result.write_string(func.name)
  result.write_string("|#\n")
  result.to_string()
}

// インターフェースからstructとメソッドを生成

///|
pub fn generate_interface_binding(iface : InterfaceDeclaration) -> String {
  let result = StringBuilder::new()

  // struct定義
  result.write_string("pub struct ")
  result.write_string(iface.name)
  result.write_string(" {\n")
  result.write_string("  value : JSValue\n")
  result.write_string("}\n\n")

  // メンバーごとにメソッドを生成
  for m in iface.members {
    match m {
      Property(prop) => {
        // getter
        result.write_string("pub fn ")
        result.write_string(iface.name)
        result.write_string("::")
        result.write_string(prop.name)
        result.write_string("(self : ")
        result.write_string(iface.name)
        result.write_string(") -> ")
        result.write_string(type_to_moonbit(prop.type_))
        result.write_string(" {\n")
        result.write_string("  self.value.get(\"")
        result.write_string(prop.name)
        result.write_string("\")\n")
        result.write_string("}\n\n")
      }
      Method(meth) => {
        // メソッド
        result.write_string("pub fn ")
        result.write_string(iface.name)
        result.write_string("::")
        result.write_string(meth.name)
        result.write_string("(self : ")
        result.write_string(iface.name)
        for param in meth.params {
          result.write_string(", ")
          result.write_string(parameter_to_moonbit(param))
        }
        result.write_string(") -> ")
        result.write_string(type_to_moonbit(meth.return_type))
        result.write_string(" {\n")
        result.write_string("  self.value.call(\"")
        result.write_string(meth.name)
        result.write_string("\")\n")
        result.write_string("}\n\n")
      }
      _ => ()
    }
  }
  result.to_string()
}

// クラスからFFIバインディングを生成

///|
pub fn generate_class_binding(cls : ClassDeclaration) -> String {
  let result = StringBuilder::new()

  // struct定義
  result.write_string("pub struct ")
  result.write_string(cls.name)
  result.write_string(" {\n")
  result.write_string("  value : JSValue\n")
  result.write_string("}\n\n")

  // コンストラクタがあれば生成
  for m in cls.members {
    match m {
      ClassConstructor(ctor) => {
        result.write_string("pub fn ")
        result.write_string(cls.name)
        result.write_string("::new(")
        let params = ctor.params.map(fn(p) { parameter_to_moonbit(p) })
        result.write_string(params.join(", "))
        result.write_string(") -> ")
        result.write_string(cls.name)
        result.write_string(" {\n")
        result.write_string("  ")
        result.write_string(cls.name)
        result.write_string("::{value: js_new(\"")
        result.write_string(cls.name)
        result.write_string("\")}\n")
        result.write_string("}\n\n")
      }
      _ => ()
    }
  }
  result.to_string()
}

// 型エイリアスからFFIバインディングを生成

///|
pub fn generate_type_alias_binding(type_alias : TypeAliasDeclaration) -> String {
  let result = StringBuilder::new()
  result.write_string("// Type alias: ")
  result.write_string(type_alias.name)
  result.write_string("\n")
  // Use new typealias syntax: typealias OriginalType as AliasName
  result.write_string("pub typealias ")
  result.write_string(type_to_moonbit(type_alias.type_))
  result.write_string(" as ")
  result.write_string(type_alias.name)
  if type_alias.type_params.length() > 0 {
    result.write_string("[")
    result.write_string(type_alias.type_params.join(", "))
    result.write_string("]")
  }
  result.write_string("\n\n")
  result.to_string()
}

// Declaration全体からFFIコードを生成

///|
pub fn generate_ffi_code(declarations : Array[Declaration]) -> String {
  let result = StringBuilder::new()
  result.write_string("// Auto-generated FFI bindings from TypeScript\n\n")
  for decl in declarations {
    match decl {
      Function(func) => {
        result.write_string(generate_function_binding(func))
        result.write_string("\n")
      }
      Interface(iface) => {
        result.write_string(generate_interface_binding(iface))
        result.write_string("\n")
      }
      Class(cls) => {
        result.write_string(generate_class_binding(cls))
        result.write_string("\n")
      }
      TypeAlias(type_alias) => {
        result.write_string(generate_type_alias_binding(type_alias))
        result.write_string("\n")
      }
      Export(export_decl) =>
        match export_decl.declaration {
          Some(inner_decl) => {
            // Export内の宣言を処理
            let code = generate_ffi_code([inner_decl])
            result.write_string(code)
          }
          None => ()
        }
      _ => ()
    }
  }
  result.to_string()
}
