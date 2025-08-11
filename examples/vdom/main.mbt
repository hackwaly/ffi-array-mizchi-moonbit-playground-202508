fn main {
  println("=== Virtual DOM Example ===")
  
  // 初期のVNodeを作成
  let old_vdom = @vdom.div(
    @vdom.attrs_of([("class", "container"), ("id", "main")]),
    [
      @vdom.h("h1", Map::new(), [@vdom.text("Hello World")]),
      @vdom.p(@vdom.attrs_of([("class", "description")]), [@vdom.text("This is a paragraph")]),
      @vdom.button(@vdom.attrs_of([("onclick", "handleClick")]), [@vdom.text("Click me")])
    ]
  )
  
  // 更新後のVNodeを作成
  let new_vdom = @vdom.div(
    @vdom.attrs_of([("class", "container updated"), ("id", "main")]),
    [
      @vdom.h("h1", Map::new(), [@vdom.text("Hello MoonBit!")]),
      @vdom.p(@vdom.attrs_of([("class", "description new")]), [@vdom.text("This is an updated paragraph")]),
      @vdom.button(@vdom.attrs_of([("onclick", "handleClick"), ("disabled", "true")]), [@vdom.text("Clicked!")]),
      @vdom.span(Map::new(), [@vdom.text("New element")])
    ]
  )
  
  // 差分を計算
  let patches = @vdom.diff(Some(old_vdom), Some(new_vdom))
  
  println("Patches count: \{patches.length()}")
  for i = 0; i < patches.length(); i = i + 1 {
    match patches[i] {
      @vdom.Patch::UpdateAttributes(_) => println("- UpdateAttributes")
      @vdom.Patch::ReplaceChild(index, _) => println("- ReplaceChild at index \{index}")
      @vdom.Patch::AppendChild(_) => println("- AppendChild")
      _ => println("- Other patch")
    }
  }
  
  // DOMの作成と更新をシミュレート
  let initial_dom = @vdom.create_dom_from_vnode(old_vdom)
  println("\nInitial DOM created")
  
  match initial_dom {
    @vdom.DOMNodeType::ElementNode(node) => {
      println("Root tag: \{node.tag}")
      println("Children count: \{node.children.length()}")
    }
    _ => ()
  }
  
  // パッチを適用
  let updated_dom = @vdom.apply_patch(Some(initial_dom), patches)
  println("\nPatches applied")
  
  match updated_dom {
    Some(@vdom.DOMNodeType::ElementNode(node)) => {
      println("Updated root tag: \{node.tag}")
      println("Updated children count: \{node.children.length()}")
      match node.attributes.get("class") {
        Some(cls) => println("Updated class: \{cls}")
        None => ()
      }
    }
    _ => ()
  }
}