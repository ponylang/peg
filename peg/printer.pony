use "collections"

primitive Printer
  """
  Pretty-prints a parse tree as indented S-expressions. Each node is printed
  as `(label ...)` with children indented below it; tokens are printed as
  `(label text)` on a single line.
  """
  fun apply(p: ASTChild, depth: USize = 0, indent: String = "  ",
    s: String ref = String): String ref
  =>
    """
    Print the parse tree rooted at `p`. Pass a `String ref` as `s` to
    append to an existing buffer; otherwise a new string is allocated.
    """
    _indent(depth, indent, s)
    s.append("(")
    s.append(p.label().text())

    match p
    | let ast: AST =>
      s.append("\n")
      for child in ast.children.values() do
        Printer(child, depth + 1, indent, s)
      end
      _indent(depth, indent, s)
    | let token: Token =>
      s.append(" ")
      s.append(token.source.content, token.offset, token.length)
    end
    s.append(")\n")
    s

  fun _indent(depth: USize, indent: String, s: String ref) =>
    for i in Range(0, depth) do
      s.append(indent)
    end
