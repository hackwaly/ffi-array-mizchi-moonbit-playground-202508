test "simple text node diff" {
  let old = Some(text("Hello"))
  let new = Some(text("World"))
  let patches = diff(old, new)
  
  assert_eq!(patches.length(), 1)
  match patches[0] {
    Patch::UpdateText(content) => assert_eq!(content, "World")
    _ => abort("Expected UpdateText patch")
  }
}

test "element creation" {
  let old : VNode? = None
  let new = Some(div(Map::new(), [text("Hello")]))
  let patches = diff(old, new)
  
  assert_eq!(patches.length(), 1)
  match patches[0] {
    Patch::Create(_) => ()
    _ => abort("Expected Create patch")
  }
}

test "element removal" {
  let old = Some(div(Map::new(), [text("Hello")]))
  let new : VNode? = None
  let patches = diff(old, new)
  
  assert_eq!(patches.length(), 1)
  match patches[0] {
    Patch::Remove => ()
    _ => abort("Expected Remove patch")
  }
}

test "attribute update" {
  let old_attrs = attrs_of([("class", "old"), ("id", "test")])
  let new_attrs = attrs_of([("class", "new"), ("id", "test")])
  
  let old = Some(div(old_attrs, []))
  let new = Some(div(new_attrs, []))
  let patches = diff(old, new)
  
  assert_eq!(patches.length(), 1)
  match patches[0] {
    Patch::UpdateAttributes(attrs) => {
      match attrs.get("class") {
        Some(v) => assert_eq!(v, "new")
        None => abort("class attribute not found")
      }
    }
    _ => abort("Expected UpdateAttributes patch")
  }
}

test "child append" {
  let old = Some(div(Map::new(), [text("First")]))
  let new = Some(div(Map::new(), [text("First"), text("Second")]))
  let patches = diff(old, new)
  
  let mut has_append = false
  for i = 0; i < patches.length(); i = i + 1 {
    match patches[i] {
      Patch::AppendChild(_) => has_append = true
      _ => ()
    }
  }
  
  assert_true!(has_append)
}

test "child removal" {
  let old = Some(div(Map::new(), [text("First"), text("Second")]))
  let new = Some(div(Map::new(), [text("First")]))
  let patches = diff(old, new)
  
  let mut has_remove = false
  for i = 0; i < patches.length(); i = i + 1 {
    match patches[i] {
      Patch::RemoveChild(_) => has_remove = true
      _ => ()
    }
  }
  
  assert_true!(has_remove)
}

test "complex structure diff" {
  let old = Some(
    div(
      attrs_of([("class", "container")]),
      [
        h("h1", Map::new(), [text("Title")]),
        p(Map::new(), [text("Paragraph 1")]),
        p(Map::new(), [text("Paragraph 2")])
      ]
    )
  )
  
  let new = Some(
    div(
      attrs_of([("class", "container updated")]),
      [
        h("h1", Map::new(), [text("New Title")]),
        p(Map::new(), [text("Paragraph 1")]),
        p(Map::new(), [text("Paragraph 3")]),
        button(Map::new(), [text("Click me")])
      ]
    )
  )
  
  let patches = diff(old, new)
  assert_true!(patches.length() > 0)
}

test "patch application" {
  let vnode = div(
    attrs_of([("class", "test")]),
    [text("Hello")]
  )
  
  let dom = create_dom_from_vnode(vnode)
  match dom {
    DOMNodeType::ElementNode(node) => {
      assert_eq!(node.tag, "div")
      match node.attributes.get("class") {
        Some(v) => assert_eq!(v, "test")
        None => abort("class attribute not found")
      }
    }
    _ => abort("Expected ElementNode")
  }
}