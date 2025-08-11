pub fn h(
  tag : String,
  attrs : Map[String, String],
  children : Array[VNode]
) -> VNode {
  VNode::Element(tag, attrs, children)
}

pub fn text(content : String) -> VNode {
  VNode::Text(content)
}

pub fn div(
  attrs : Map[String, String],
  children : Array[VNode]
) -> VNode {
  h("div", attrs, children)
}

pub fn span(
  attrs : Map[String, String],
  children : Array[VNode]
) -> VNode {
  h("span", attrs, children)
}

pub fn p(
  attrs : Map[String, String],
  children : Array[VNode]
) -> VNode {
  h("p", attrs, children)
}

pub fn button(
  attrs : Map[String, String],
  children : Array[VNode]
) -> VNode {
  h("button", attrs, children)
}

pub fn attrs_of(pairs : Array[(String, String)]) -> Map[String, String] {
  let map = Map::new()
  for i = 0; i < pairs.length(); i = i + 1 {
    let (key, value) = pairs[i]
    map[key] = value
  }
  map
}