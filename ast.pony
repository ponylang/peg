class val AST
  // let label: Label
  embed children: Array[(AST | Token | NotPresent)] = children.create()

  new iso create(/*label': Label*/) =>
    // label = label'
    None

  fun ref push(some: (AST | Token | NotPresent)) =>
    children.push(some)

  fun size(): USize => children.size()

  fun extract(): (AST | Token | NotPresent) =>
    try children(0) else NotPresent end
