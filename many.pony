class Many is Parser
  let _a: Parser
  let _sep: Parser
  var _label: Label
  let _require: Bool

  new create(a: Parser, sep: Parser, l: Label, require: Bool) =>
    _a = a
    _sep = sep
    _label = l
    _require = require

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

    while true do
      match _a.parse(source, offset + length, true, hidden)
      | (let advance: USize, Skipped) =>
        length = length + advance
      | (let advance: USize, let r: (AST | Token | NotPresent)) =>
        ast.push(r)
        length = length + advance
      else
        break
      end

      match _sep.parse(source, offset + length, true, hidden)
      | (let advance: USize, let r: ParseOK) =>
        length = length + advance
      else
        break
      end
    end

    if _require and (length == 0) then
      (0, ParseFail)
    else
      (length, consume ast)
    end

  fun _parse_token(source: String, offset: USize): ParseResult =>
    var length = USize(0)

    while true do
      match _a.parse(source, offset + length, false, NoParser)
      | (0, NotPresent)
      | (0, Skipped) => None
      | (let advance: USize, Lex) =>
        length = length + advance
      else
        break
      end

      match _sep.parse(source, offset + length, false, NoParser)
      | (let advance: USize, let r: ParseOK) =>
        length = length + advance
      else
        break
      end
    end

    if _require and (length == 0) then
      (0, ParseFail)
    else
      (length, Lex)
    end
