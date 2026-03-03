// A child element in a parse tree: an AST subtree, a Token leaf, or
// NotPresent (from an optional that didn't match).
type ASTChild is (AST | Token | NotPresent)

class val AST
  """
  A labeled node in the parse tree. Contains an ordered list of children
  (other AST nodes, Tokens, or NotPresent values from optional matches).
  """
  let _label: Label
  embed children: Array[ASTChild] = children.create()

  new iso create(label': Label = NoLabel) =>
    _label = label'

  fun ref push(some: ASTChild) =>
    """Append a child to this node."""
    children.push(some)

  fun label(): Label =>
    """This node's label."""
    _label

  fun size(): USize =>
    """The number of children."""
    children.size()

  fun extract(): ASTChild =>
    """Return the first child, or `NotPresent` if there are none."""
    try children(0)? else NotPresent end
