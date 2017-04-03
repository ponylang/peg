type ParseResult is (USize, (ParseOK | Parser))

type ParseOK is
  ( AST
  | Token
  | NotPresent
  | Skipped
  | Lex
  )

primitive NotPresent
  """
  Returned by Option when the parse isn't found
  """

primitive Skipped
  """
  Returned by Skip when the parse is found, and Not when the parse isn't found.
  """

primitive Lex
  """
  Returned when a parse tree isn't neeeded
  """

trait box Parser
  fun parse(source: String, offset: USize = 0, tree: Bool = true,
    hidden: Parser = NoParser): ParseResult

  fun skip_hidden(source: String, offset: USize, hidden: Parser): USize =>
    """
    Return a new start location, skipping over hidden tokens.
    """
    offset + hidden.parse(source, offset, false, NoParser)._1

  fun result(source: String, offset: USize, from: USize, length: USize,
    tree: Bool, l: Label = NoLabel): ParseResult
  =>
    """
    Once a terminal parser has an offset and length, it should call `result` to
    return either a token (if a tree is requested) or a new lexical position.
    """
    if tree then
      ((from - offset) + length, Token(l, source, from, length))
    else
      ((from - offset) + length, Lex)
    end

  fun mul(that: Parser, l: Label = NoLabel): Parser => Sequence(this, that, l)
  fun div(that: Parser): Parser => Choice(this, that)
  fun skip(): Parser => Skip(this)
  fun opt(): Parser => Option(this)
  fun many(sep: Parser = NoParser, l: Label = NoLabel): Parser =>
    Many(this, sep, l, false)
  fun many1(sep: Parser = NoParser, l: Label = NoLabel): Parser =>
    Many(this, sep, l, true)
  fun op_not(): Parser => Not(this)
  fun op_and(): Parser => Not(Not(this))
  fun hide(that: Parser): Parser => Hidden(this, that)
  fun term(l: Label = NoLabel): Parser => Terminal(this, l)
  fun eof(): Parser => EndOfFile(this)

primitive NoParser is Parser
  fun parse(source: String, offset: USize, tree: Bool, hidden: Parser)
    : ParseResult
  =>
    (0, Lex)

trait val Label
  new val create()
  fun text(): String

primitive NoLabel is Label fun text(): String => ""
