class box Option is Parser
  let _a: Parser

  new box create(a: Parser) =>
    _a = a

  fun parse(source: String, offset: USize, tree: Bool, hidden: Parser)
    : ParseResult
  =>
    match _a.parse(source, offset, tree, hidden)
    | (let offset': USize, let r: ParseOK) => (offset', r)
    else
      (offset, NotPresent)
    end
