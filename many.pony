class box Many is Parser
  let _a: Parser
  let _require: Bool

  new box create(a: Parser, require: Bool) =>
    _a = a
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
    var offset' = offset
    var matched = false
    let ast = AST

    while true do
      match _a.parse(source, offset', true, hidden)
      | (let offset'': USize, Skipped) =>
        offset' = offset''
        matched = true
      | (let offset'': USize, let r: (AST | Token | NotPresent)) =>
        ast.push(r)
        offset' = offset''
        matched = true
      else
        break
      end
    end

    if _require and not matched then
      (0, ParseFail)
    else
      (offset', consume ast)
    end

  fun _parse_token(source: String, offset: USize): ParseResult =>
    var offset' = offset
    var matched = false

    while true do
      match _a.parse(source, offset', false, NoParser)
      | (0, NotPresent)
      | (0, Skipped) => None
      | (let offset'': USize, Lex) =>
        offset' = offset''
        matched = true
      else
        break
      end
    end

    if _require and not matched then
      (0, ParseFail)
    else
      (offset', Lex)
    end
