class box Sequence is Parser
  let _seq: Array[Parser]

  new box create(a: Parser, b: Parser) =>
    _seq = [a; b]

  new box concat(a: Sequence, b: Parser) =>
    let r = a._seq.clone()
    r.push(b)
    _seq = consume r

  fun mul(that: Parser): Sequence =>
    concat(this, that)

  fun parse(source: String, offset: USize, tree: Bool, hidden: Parser)
    : ParseResult
  =>
    if tree then
      _parse_tree(source, offset, hidden)
    else
      _parse_token(source, offset)
    end

  fun _parse_tree(source: String, offset: USize, hidden: Parser): ParseResult =>
    var offset' = offset
    let ast = AST

    for p in _seq.values() do
      match p.parse(source, offset', true, hidden)
      | (let offset'': USize, Skipped) =>
        offset' = offset''
      | (let offset'': USize, let r: (AST | Token | NotPresent)) =>
        ast.push(r)
        offset' = offset''
      else
        return (0, ParseFail)
      end
    end

    (offset', consume ast)

  fun _parse_token(source: String, offset: USize): ParseResult =>
    var offset' = offset

    for p in _seq.values() do
      match p.parse(source, offset', false, NoParser)
      | (0, NotPresent)
      | (0, Skipped) => None
      | (let offset'': USize, Lex) => offset' = offset''
      else
        return (0, ParseFail)
      end
    end

    (offset', Lex)
