class box Choice is Parser
  """
  Given a sequence of parser rules, return the result of the first rule that
  matches. Note that the result is deterministic: if more than one of the rules
  could match, the first in the list will be chosen.
  """
  let _seq: Array[Parser]

  new box create(a: Parser, b: Parser) =>
    _seq = [a; b]

  new box concat(a: Choice, b: Parser) =>
    let r = a._seq.clone()
    r.push(b)
    _seq = consume r

  fun div(that: Parser): Choice =>
    concat(this, that)

  fun parse(source: String, offset: USize, tree: Bool, hidden: Parser)
    : ParseResult
  =>
    for p in _seq.values() do
      match p.parse(source, offset, tree, hidden)
      | (let offset': USize, let r: ParseOK) => return (offset', r)
      end
    end
    (0, ParseFail)
