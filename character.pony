primitive Character is Parser
  fun parse(source: String, offset: USize, tree: Bool, hidden: Parser)
    : ParseResult
  =>
    let offset' = skip_hidden(source, offset, hidden)

    if offset' < source.size() then
      result(source, offset', 1, tree)
    else
      (0, ParseFail)
    end
