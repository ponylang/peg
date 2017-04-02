class box Not is Parser
  """
  If the parse succeeds, then fail. Otherwise, return a zero length Skipped.
  """
  let _a: Parser

  new box create(a: Parser) =>
    _a = a

  fun parse(source: String, offset: USize, tree: Bool, hidden: Parser)
    : ParseResult
  =>
    match _a.parse(source, offset, tree, hidden)
    | (let offset': USize, let r: ParseOK) =>
      (0, ParseFail)
    else
      (offset, Skipped)
    end
