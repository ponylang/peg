class box Skip is Parser
  let _a: Parser

  new box create(a: Parser) =>
    _a = a

  fun parse(source: String, offset: USize, tree: Bool, hidden: Parser)
    : ParseResult
  =>
    match _a.parse(source, offset, false, hidden)
    | (let offset': USize, let r: ParseOK) => (offset', Skipped)
    else
      (0, ParseFail)
    end
