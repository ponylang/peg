class box Terminal is Parser
  """
  A terminal parser accumulates a single lexical token rather than an AST. It
  applies the hidden channel once before starting, but not while parsing its
  elements.
  """
  let _a: Parser

  new box create(a: Parser) =>
    _a = a

  fun parse(source: String, offset: USize, tree: Bool, hidden: Parser)
    : ParseResult
  =>
    let offset' = skip_hidden(source, offset, hidden)

    match _a.parse(source, offset', false, NoParser)
    | (let length: USize, Lex) =>
      result(source, offset', length, tree)
    else
      (0, ParseFail)
    end
