class Skip is Parser
  """
  Matches the wrapped parser but omits it from the parse tree, returning
  `Skipped` on success. This is a PEG extension (`-e` in PEG files, `-e`
  in combinators) used for syntactic punctuation like brackets and keywords
  that are needed for parsing but carry no semantic value.
  """
  let _a: Parser

  new create(a: Parser) =>
    _a = a

  fun parse(source: Source, offset: USize, tree: Bool, hidden: Parser)
    : ParseResult
  =>
    match _a.parse(source, offset, false, hidden)
    | (let advance: USize, let r: ParseOK) => (advance, Skipped)
    | (let advance: USize, let r: Parser) => (advance, r)
    else
      (0, this)
    end

  fun error_msg(): String => _a.error_msg()
