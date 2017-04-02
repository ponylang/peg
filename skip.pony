class Skip is Parser
  let _a: Parser

  new create(a: Parser) =>
    _a = a

  fun parse(source: String, offset: USize, tree: Bool, hidden: Parser)
    : ParseResult
  =>
    match _a.parse(source, offset, false, hidden)
    | (let advance: USize, let r: ParseOK) => (advance, Skipped)
    else
      (0, ParseFail)
    end
