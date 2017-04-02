primitive Character is Parser
  fun parse(source: String, offset: USize, tree: Bool, hidden: Parser)
    : ParseResult
  =>
    let from = skip_hidden(source, offset, hidden)

    if from < source.size() then
      result(source, offset, from, 1, tree)
    else
      (0, ParseFail)
    end
