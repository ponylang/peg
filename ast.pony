class val AST
  // let label: Label
  embed children: Array[(AST | Token | NotPresent)] = children.create()

  new iso create(/*label': Label*/) =>
    // label = label'
    None

  fun ref push(some: (AST | Token | NotPresent)) =>
    children.push(some)

  fun print(out: OutStream) =>
    out.print("(")
    for p in children.values() do
      match p
      | let ast: AST => ast.print(out)
      | let token: Token => token.print(out)
      | let none: NotPresent => out.print("x")
      end
    end
    out.print(")")
