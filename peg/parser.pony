// The result of a parse attempt: the number of bytes consumed and either a
// successful parse (ParseOK) or the Parser that failed.
type ParseResult is (USize, (ParseOK | Parser))

// A successful parse result: an AST node, a Token leaf, NotPresent (from
// Option), Skipped (from Skip/Not), or Lex (when tree building is off).
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
  fun label(): Label => NoLabel

primitive Skipped
  """
  Returned by Skip when the parse is found, and Not when the parse isn't found.
  """

primitive Lex
  """
  Returned when a parse tree isn't needed.
  """

trait box Parser
  """
  A parsing expression that can be applied to source text. Parsers are composed
  using operator sugar: `*` for sequence, `/` for ordered choice, `-` for skip,
  and `not` for negation.
  """
  fun parse(source: Source, offset: USize = 0, tree: Bool = true,
    hidden: Parser = NoParser): ParseResult
    """
    Parse `source` starting at byte `offset`. When `tree` is true, build an AST;
    when false, only track the lexical position. The `hidden` parser defines
    whitespace/comments to skip between tokens.
    """

  fun error_msg(): String =>
    """
    A human-readable description of what this parser expected. Used to build
    error messages on parse failure.
    """
    "not to see an error in this parser"

  fun skip_hidden(source: Source, offset: USize, hidden: Parser): USize =>
    """
    Return a new start location, skipping over hidden tokens.
    """
    offset + hidden.parse(source, offset, false, NoParser)._1

  fun result(source: Source, offset: USize, from: USize, length: USize,
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

  fun mul(that: Parser): Sequence =>
    """Sequence operator: `a * b` matches a then b."""
    Sequence(this, that)

  fun div(that: Parser): Choice =>
    """Ordered choice operator: `a / b` tries a first, then b."""
    Choice(this, that)

  fun neg(): Skip =>
    """Skip operator: `-a` matches a but omits it from the tree."""
    Skip(this)

  fun opt(): Option =>
    """Option: `a.opt()` matches a or succeeds with `NotPresent`."""
    Option(this)

  fun many(sep: Parser = NoParser): Many =>
    """Zero or more: `a.many()` or `a.many(sep)` for separated lists."""
    Many(this, sep, false)

  fun many1(sep: Parser = NoParser): Many =>
    """One or more: `a.many1()` or `a.many1(sep)` for separated lists."""
    Many(this, sep, true)

  fun op_not(): Not =>
    """Not predicate: `not a` succeeds if a fails, consuming nothing."""
    Not(this)

  fun op_and(): Not =>
    """And predicate: succeeds if a matches, consuming nothing."""
    Not(Not(this))

  fun hide(that: Parser): Hidden =>
    """Set the hidden channel (whitespace/comments) for this parser."""
    Hidden(this, that)

  fun term(l: Label = NoLabel): Terminal =>
    """Wrap as a terminal that produces a single `Token` leaf."""
    Terminal(this, l)

  fun eof(): EndOfFile =>
    """Require the entire input to be consumed after this parser."""
    EndOfFile(this)

primitive NoParser is Parser
  """
  A null parser that matches nothing. Used as a default/sentinel value where
  a parser is required but none is active (e.g. default hidden channel, default
  separator in `Many`).
  """
  fun parse(source: Source, offset: USize, tree: Bool, hidden: Parser)
    : ParseResult
  =>
    (0, Lex)

  fun error_msg(): String => "not to be using NoParser"

trait val Label
  """
  A label identifies AST nodes and tokens in the parse tree. Define custom
  labels as primitives implementing this trait to tag your grammar's rules.
  """
  fun text(): String

primitive NoLabel is Label
  """The default empty label, used when no label has been assigned."""
  fun text(): String => ""
