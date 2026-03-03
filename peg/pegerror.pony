use "collections"
use "term"

// An error marker: (source, byte offset, length, message). Used by
// PegFormatError to point at specific locations in the source text.
type Marker is (Source, USize, USize, String)

trait box PegError
  """
  Base trait for errors produced during parsing or grammar compilation.
  """
  // Short category name (e.g. "Syntax Error", "Missing Definition").
  fun category(): String
  // Human-readable explanation of the error.
  fun description(): String
  // Source locations related to this error, with explanatory messages.
  fun markers(): Iterator[Marker] => Array[Marker].values()

class SyntaxError is PegError
  """
  A parse failed at a specific offset. Wraps the failing parser so its
  `error_msg()` can describe what was expected.
  """
  let source: Source
  let offset: USize
  let parser: Parser

  new create(source': Source, offset': USize, parser': Parser) =>
    source = source'
    offset = offset'
    parser = parser'

  fun category(): String => "Syntax Error"

  fun description(): String =>
    """
    There is a syntax error that has prevented the parser from being able to
    understand the source text.
    """

  fun markers(): Iterator[Marker] =>
    [(source, offset, USize(1), "expected " + parser.error_msg())].values()

class val DuplicateDefinition is PegError
  """A rule name was defined more than once in a PEG grammar."""
  let def: Token
  let prev: Token

  new val create(def': Token, prev': Token) =>
    def = def'
    prev = prev'

  fun category(): String => "Duplicate Definition"

  fun description(): String =>
    """
    One of the parse rules has been defined more than once.
    """

  fun markers(): Iterator[Marker] =>
    [ (def.source, def.offset, def.length, "rule has been defined more than once")
      (prev.source, prev.offset, prev.length, "previous definition is here")
    ].values()

class val MissingDefinition is PegError
  """A rule references another rule that has not been defined."""
  let token: Token

  new val create(token': Token) =>
    token = token'

  fun category(): String => "Missing Definition"

  fun description(): String =>
    """
    One of the parse rules references another rule that has not been defined.
    """

  fun markers(): Iterator[Marker] =>
    [ (token.source, token.offset, token.length, "rule has not been defined")
    ].values()

class val UnknownNodeLabel is PegError
  """An unrecognized label was encountered in the PEG AST during compilation."""
  let label: Label

  new val create(label': Label) =>
    label = label'

  fun category(): String => "Unknown Node Label"

  fun description(): String =>
    """
    There is an internal error that has resulted in an unknown node label in
    the abstract syntax tree that describes the parsing expression grammar.
    """

primitive NoStartDefinition is PegError
  """The grammar has no `start` rule."""
  fun category(): String => "No Start Rule"
  fun description(): String =>
    """
    A parsing expression grammar must have a 'start' rule. This is the initial
    rule that is applied to the source text to parse it.
    """

primitive MalformedAST is PegError
  """The PEG AST has a structure the compiler does not understand."""
  fun category(): String => "Malformed AST"
  fun description(): String =>
    """
    There is an internal error that has resulted in an abstract syntax tree
    that the compiler does not understand.
    """

primitive PegFormatError
  """
  Formats `PegError` values for display on a terminal or as JSON.
  """
  fun console(e: PegError val, colorize: Bool = true): ByteSeqIter =>
    """
    Format an error for terminal output. Set `colorize` to false to omit
    ANSI escape sequences (useful when piping to non-terminal destinations).
    """
    let text =
      recover
        [ if colorize then ANSI.cyan() else "" end
          "-- "; e.category(); " --\n\n"
          if colorize then ANSI.reset() else "" end
        ]
      end

    for m in e.markers() do
      (let line, let col) = Position(m._1, m._2)
      let source = Position.text(m._1, m._2, col)
      let indent = Position.indent(source, col)
      let mark = recover String(m._3) end

      for i in Range(0, m._3) do
        mark.append("^")
      end

      let line_text: String = line.string()
      let line_indent = Position.indent(line_text, line_text.size() + 1)

      text.append(
        recover
          [ if colorize then ANSI.grey() else "" end
            m._1.path; ":"; line_text; ":"; col.string(); ":"; m._3.string()
            "\n\n"
            line_text; ": "
            if colorize then ANSI.reset() else "" end
            source; "\n"
            if colorize then ANSI.red() else "" end
            line_indent; "  "; indent; consume mark; "\n"
            line_indent; "  "; indent; m._4
            if colorize then ANSI.reset() else "" end
            "\n\n"
          ]
        end
        )
    end

    text.append(
      recover
        [ e.description()
          "\n\n"
        ]
      end
      )

    text

  fun json(e: PegError val): ByteSeqIter =>
    """Format an error as a JSON object."""
    let text =
      recover
        [ "{\n  \"category\": \""
          e.category()
          "\"\n  \"description\": \""
          e.description()
          "\"\n  \"markers\":\n  [\n"
        ]
      end

    for m in e.markers() do
      (let line, let col) = Position(m._1, m._2)

      text.append(
        recover
          [ as String:
            "    {\n"
            "      \"file\": \""; m._1.path; "\"\n"
            "      \"line\": "; line.string(); "\n"
            "      \"column\": "; col.string(); "\n"
            "      \"length\": "; m._3.string(); "\n"
            "      \"text\": \""; m._4; "\"\n"
            "    }\n"
          ]
        end
        )
    end

    text.push("  ]\n}\n")
    text
