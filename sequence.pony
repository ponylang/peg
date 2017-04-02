class Sequence is Parser
  let _seq: Array[Parser]
  var _label: Label

  new create(a: Parser, b: Parser, l: Label = NoLabel) =>
    _seq = [a; b]
    _label = l

  new concat(a: Sequence box, b: Parser) =>
    let r = a._seq.clone()
    r.push(b)
    _seq = consume r
    _label = a._label

  fun ref label(l: Label): Sequence =>
    _label = l
    this

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
    var length = USize(0)
    let ast = AST(_label)

    for p in _seq.values() do
      match p.parse(source, offset + length, true, hidden)
      | (let advance: USize, Skipped) =>
        length = length + advance
      | (let advance: USize, let r: (AST | Token | NotPresent)) =>
        ast.push(r)
        length = length + advance
      else
        return (0, ParseFail)
      end
    end

    match ast.size()
    | 0 => (length, Skipped)
    | 1 => (length, ast.extract())
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
      else
        return (0, ParseFail)
      end
    end

    (length, Lex)
