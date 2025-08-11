pub fn diff(old : VNode?, new : VNode?) -> Array[Patch] {
  match (old, new) {
    (None, None) => []
    (None, Some(new_node)) => [Patch::Create(new_node)]
    (Some(_), None) => [Patch::Remove]
    (Some(old_node), Some(new_node)) => diff_nodes(old_node, new_node)
  }
}

fn diff_nodes(old : VNode, new : VNode) -> Array[Patch] {
  match (old, new) {
    (VNode::Text(old_text), VNode::Text(new_text)) => {
      if old_text == new_text {
        []
      } else {
        [Patch::UpdateText(new_text)]
      }
    }
    (VNode::Element(old_tag, old_attrs, old_children), VNode::Element(new_tag, new_attrs, new_children)) => {
      if old_tag != new_tag {
        [Patch::Replace(VNode::Element(new_tag, new_attrs, new_children))]
      } else {
        let patches = []
        
        let attr_patches = diff_attributes(old_attrs, new_attrs)
        for i = 0; i < attr_patches.length(); i = i + 1 {
          patches.push(attr_patches[i])
        }
        
        let child_patches = diff_children(old_children, new_children)
        for i = 0; i < child_patches.length(); i = i + 1 {
          patches.push(child_patches[i])
        }
        
        patches
      }
    }
    (_, new_node) => [Patch::Replace(new_node)]
  }
}

fn diff_attributes(
  old_attrs : Map[String, String],
  new_attrs : Map[String, String]
) -> Array[Patch] {
  let changed = Map::new()
  
  for kv in new_attrs.iter() {
    let (key, value) = kv
    match old_attrs.get(key) {
      None => changed[key] = value
      Some(old_value) => {
        if old_value != value {
          changed[key] = value
        }
      }
    }
  }
  
  for kv in old_attrs.iter() {
    let (key, _) = kv
    match new_attrs.get(key) {
      None => changed[key] = ""
      Some(_) => ()
    }
  }
  
  if changed.is_empty() {
    []
  } else {
    [Patch::UpdateAttributes(changed)]
  }
}

fn diff_children(
  old_children : Array[VNode],
  new_children : Array[VNode]
) -> Array[Patch] {
  let patches = []
  let old_len = old_children.length()
  let new_len = new_children.length()
  let min_len = if old_len < new_len { old_len } else { new_len }
  
  for i = 0; i < min_len; i = i + 1 {
    let child_patches = diff_nodes(old_children[i], new_children[i])
    for j = 0; j < child_patches.length(); j = j + 1 {
      patches.push(Patch::ReplaceChild(i, new_children[i]))
    }
  }
  
  if new_len > old_len {
    for i = old_len; i < new_len; i = i + 1 {
      patches.push(Patch::AppendChild(new_children[i]))
    }
  } else if old_len > new_len {
    for i = old_len - 1; i >= new_len; i = i - 1 {
      patches.push(Patch::RemoveChild(i))
    }
  }
  
  patches
}