class Forward is Parser
  """
  A forwarding parser is used to create mutually recursive parse rules. The
  forwarding parser can be used instead, and is updated when the real parse
  rule is created.
  """
  var _a: (Parser | None) = None

  new create() =>
    None

  fun ref update(value: Parser) =>
    _a = value

  fun parse(source: String, offset: USize, tree: Bool, hidden: Parser)
    : ParseResult
  =>
    try
      (_a as Parser).parse(source, offset, tree, hidden)
    else
      (0, this)
    end
