class Hidden is Parser
  """
  A hidden channel is used to specify whitespace, comments, and any other
  lexical tokens that should be discarded from the input stream. This replaces
  the hidden channel.
  """
  let _a: Parser
  let _hide: Parser

  new create(a: Parser, hide: Parser) =>
    _a = a
    _hide = hide

  fun parse(source: String, offset: USize, tree: Bool, hidden: Parser)
    : ParseResult
  =>
    _a.parse(source, offset, tree, _hide)
