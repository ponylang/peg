class Sequence is Parser
  let _seq: Array[Parser]
  var _label: Label

  new create(a: Parser, b: Parser, l: Label = NoLabel) =>
    _seq = [a; b]
    _label = l

  new concat(a: Sequence box, b: Parser, l: Label = NoLabel) =>
    let r = a._seq.clone()
    r.push(b)
    _seq = consume r
    _label = if l is NoLabel then a._label else l end

  fun mul(that: Parser, l: Label = NoLabel): Sequence =>
    concat(this, that, l)

  fun parse(source: String, offset: USize, tree: Bool, hidden: Parser)
    : ParseResult
  =>
    if tree then
      _parse_tree(source, offset, hidden)
    else
      _parse_token(source, offset)
    end

  fun _parse_tree(source: String, offset: USize, hidden: Parser): ParseResult =>
    var length = USize(0)
    let ast = AST(_label)

    for p in _seq.values() do
      match p.parse(source, offset + length, true, hidden)
      | (let advance: USize, Skipped) =>
        length = length + advance
      | (let advance: USize, let r: ASTChild) =>
        ast.push(r)
        length = length + advance
      | (let advance: USize, let r: Parser) => return (length + advance, r)
      else
        return (length, this)
      end
    end

    match ast.size()
    | 0 => (length, Skipped)
    | 1 if _label is NoLabel => (length, ast.extract())
    else
      (length, consume ast)
    end

  fun _parse_token(source: String, offset: USize): ParseResult =>
    var length = USize(0)

    for p in _seq.values() do
      match p.parse(source, offset + length, false, NoParser)
      | (0, NotPresent)
      | (0, Skipped) => None
      | (let advance: USize, Lex) => length = length + advance
      | (let advance: USize, let r: Parser) => return (length + advance, r)
      else
        return (length, this)
      end
    end

    (length, Lex)
