class Option is Parser
  """
  Optional match. If the wrapped parser succeeds, returns its result.
  Otherwise, succeeds with `NotPresent` (consuming no input). Corresponds
  to `e?` in PEG files and `e.opt()` in combinators.
  """
  let _a: Parser

  new create(a: Parser) =>
    _a = a

  fun parse(source: Source, offset: USize, tree: Bool, hidden: Parser)
    : ParseResult
  =>
    match _a.parse(source, offset, tree, hidden)
    | (let advance: USize, let r: ParseOK) => (advance, r)
    else
      (0, NotPresent)
    end
