use "collections"

primitive Printer
  fun apply(p: (AST box | Token box | NotPresent), depth: USize = 0,
    indent: String = "  ", s: String ref = String): String ref
  =>
    match p
    | let ast: AST box =>
      _indent(depth, indent, s)
      s.append("(")
      s.append(ast.label.text())
      s.append("\n")
      for child in ast.children.values() do
        Printer(child, depth + 1, indent, s)
      end
      _indent(depth, indent, s)
      s.append(")\n")
    | let token: Token box =>
      _indent(depth, indent, s)
      s.append("(")
      s.append(token.label.text())
      s.append(" ")
      s.append(token.source, token.offset, token.length)
      s.append(")\n")
    | NotPresent =>
      _indent(depth, indent, s)
      s.append("()\n")
    end
    s

  fun _indent(depth: USize, indent: String, s: String ref) =>
    for i in Range(0, depth) do
      s.append(indent)
    end
