pub fn apply_patch(
  dom : DOMNodeType?,
  patches : Array[Patch]
) -> DOMNodeType? {
  let mut current_dom = dom
  
  for i = 0; i < patches.length(); i = i + 1 {
    current_dom = apply_single_patch(current_dom, patches[i])
  }
  
  current_dom
}

fn apply_single_patch(
  dom : DOMNodeType?,
  patch : Patch
) -> DOMNodeType? {
  match patch {
    Patch::Create(vnode) => Some(create_dom_from_vnode(vnode))
    Patch::Remove => None
    Patch::Replace(vnode) => Some(create_dom_from_vnode(vnode))
    Patch::UpdateText(new_text) => {
      match dom {
        Some(DOMNodeType::TextNode(_)) => Some(DOMNodeType::TextNode(new_text))
        _ => dom
      }
    }
    Patch::UpdateAttributes(new_attrs) => {
      match dom {
        Some(DOMNodeType::ElementNode(node)) => {
          let updated_node = DOMNode::{
            tag: node.tag,
            attributes: new_attrs,
            children: node.children
          }
          Some(DOMNodeType::ElementNode(updated_node))
        }
        _ => dom
      }
    }
    Patch::AppendChild(vnode) => {
      match dom {
        Some(DOMNodeType::ElementNode(node)) => {
          let new_child = create_dom_from_vnode(vnode)
          let new_children = node.children.copy()
          match new_child {
            DOMNodeType::ElementNode(child_node) => {
              new_children.push(child_node)
            }
            DOMNodeType::TextNode(_) => ()
          }
          let updated_node = DOMNode::{
            tag: node.tag,
            attributes: node.attributes,
            children: new_children
          }
          Some(DOMNodeType::ElementNode(updated_node))
        }
        _ => dom
      }
    }
    Patch::RemoveChild(index) => {
      match dom {
        Some(DOMNodeType::ElementNode(node)) => {
          if index < node.children.length() {
            let new_children = []
            for i = 0; i < node.children.length(); i = i + 1 {
              if i != index {
                new_children.push(node.children[i])
              }
            }
            let updated_node = DOMNode::{
              tag: node.tag,
              attributes: node.attributes,
              children: new_children
            }
            Some(DOMNodeType::ElementNode(updated_node))
          } else {
            dom
          }
        }
        _ => dom
      }
    }
    Patch::ReplaceChild(index, vnode) => {
      match dom {
        Some(DOMNodeType::ElementNode(node)) => {
          if index < node.children.length() {
            let new_child = create_dom_from_vnode(vnode)
            let new_children = []
            for i = 0; i < node.children.length(); i = i + 1 {
              if i == index {
                match new_child {
                  DOMNodeType::ElementNode(child_node) => {
                    new_children.push(child_node)
                  }
                  DOMNodeType::TextNode(_) => {
                    new_children.push(node.children[i])
                  }
                }
              } else {
                new_children.push(node.children[i])
              }
            }
            let updated_node = DOMNode::{
              tag: node.tag,
              attributes: node.attributes,
              children: new_children
            }
            Some(DOMNodeType::ElementNode(updated_node))
          } else {
            dom
          }
        }
        _ => dom
      }
    }
  }
}

pub fn create_dom_from_vnode(vnode : VNode) -> DOMNodeType {
  match vnode {
    VNode::Text(content) => DOMNodeType::TextNode(content)
    VNode::Element(tag, attrs, children) => {
      let dom_children = []
      for i = 0; i < children.length(); i = i + 1 {
        match create_dom_from_vnode(children[i]) {
          DOMNodeType::ElementNode(child) => dom_children.push(child)
          DOMNodeType::TextNode(_) => ()
        }
      }
      DOMNodeType::ElementNode(DOMNode::{
        tag: tag,
        attributes: attrs,
        children: dom_children
      })
    }
  }
}