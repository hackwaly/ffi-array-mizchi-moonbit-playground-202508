pub enum VNode {
  Element(String, Map[String, String], Array[VNode])
  Text(String)
}

pub enum Patch {
  Create(VNode)
  Replace(VNode)
  Remove
  UpdateAttributes(Map[String, String])
  AppendChild(VNode)
  RemoveChild(Int)
  ReplaceChild(Int, VNode)
  UpdateText(String)
}

pub struct DOMNode {
  tag : String
  attributes : Map[String, String]
  children : Array[DOMNode]
} derive(Eq)

pub enum DOMNodeType {
  ElementNode(DOMNode)
  TextNode(String)
} derive(Eq)