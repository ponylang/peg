class Many is Parser
  """
  Repetition parser with optional separator. Matches an element zero or more
  times (or one or more when `require` is true). When a separator is provided,
  elements must be separated by it and trailing separators are not allowed.

  In PEG files: `e*` / `e+` for unseparated, `e % sep` / `e %+ sep` for
  separated lists. In combinators: `e.many()` / `e.many1()` and
  `e.many(sep)` / `e.many1(sep)`.
  """
  let _a: Parser
  let _sep: Parser
  var _label: Label = NoLabel
  let _require: Bool

  new create(a: Parser, sep: Parser, require: Bool) =>
    _a = a
    _sep = sep
    _require = require

  fun label(): Label =>
    """This repetition's label."""
    _label

  fun ref node(value: Label): Many =>
    """Assign a label, creating a named AST node for this repetition."""
    _label = value; this

  fun parse(source: Source, offset: USize, tree: Bool, hidden: Parser)
    : ParseResult
  =>
    if tree then
      _parse_tree(source, offset, hidden)
    else
      _parse_token(source, offset)
    end

  fun _parse_tree(source: Source, offset: USize, hidden: Parser): ParseResult =>
    var length = USize(0)
    var trailing = false
    let ast = AST(_label)

    while true do
      match _a.parse(source, offset + length, true, hidden)
      | (let advance: USize, Skipped) =>
        length = length + advance
      | (let advance: USize, let r: ASTChild) =>
        ast.push(r)
        length = length + advance
      | (let advance: USize, let r: Parser) =>
        if trailing and (advance > 0) then
          return (length + advance, r)
        else
          break
        end
      else
        break
      end

      match _sep.parse(source, offset + length, true, hidden)
      | (let advance: USize, let r: ParseOK) =>
        if advance > 0 then
          length = length + advance
          trailing = true
        end
      else
        trailing = false
        break
      end
    end

    if _require and (length == 0) then
      (0, this)
    elseif trailing then
      (length, this)
    else
      (length, consume ast)
    end

  fun _parse_token(source: Source, offset: USize): ParseResult =>
    var length = USize(0)
    var trailing = false

    while true do
      match _a.parse(source, offset + length, false, NoParser)
      | (0, NotPresent)
      | (0, Skipped) => None
      | (let advance: USize, Lex) =>
        length = length + advance
      | (let advance: USize, let r: Parser) =>
        if trailing and (advance > 0) then
          return (length + advance, r)
        else
          break
        end
      else
        break
      end

      match _sep.parse(source, offset + length, false, NoParser)
      | (let advance: USize, let r: ParseOK) =>
        if advance > 0 then
          length = length + advance
          trailing = true
        end
      else
        trailing = false
        break
      end
    end

    if _require and (length == 0) then
      (0, this)
    elseif trailing then
      (length, this)
    else
      (length, Lex)
    end

  fun error_msg(): String =>
    let sinp = _sep isnt NoParser

    recover
      let s = String
      if _require then s.append("at least one ") end
      s.append("element")
      if sinp then
        s.append(" without a trailing separator")
      end
      s
    end
