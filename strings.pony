/*
use "collections"

primitive TString is Label

trait StringTerminal[E: Escape] is Parser
  fun start(): String
  fun finish(): String

  // TODO: new API
  fun parse(source: String, offset: USize): ParseResult =>
    let s = start()
    let f = finish()
    let e = E.start()

    if source.at(s, offset.isize()) then
      var advance = s.size()

      while (offset + advance) < source.size() do
        if source.at(e, (offset + advance).isize()) then
          // Start an escape sequence
          let len = 
            try
              E(source, offset + advance + e.size())
            else
              // Invalid escape sequence
              return (0, ParseFail)
            end

          advance = advance + len

          // Immediately try the finish sequence
          if source.at(f, (offset + advance).isize()) then
            return (advance + f.size(), TString)
          end
        elseif source.at(f, (offset + advance).isize()) then
          return (advance + f.size(), TString)
        else
          advance = advance + 1
        end
      end
    end
    (0, ParseFail)

trait Escape
  new box create()
  fun start(): String

  fun apply(source: String, offset: USize): USize ?
    """
    Return the number of character the escape sequence consumes. This accounts
    for the escape start sequence as well, so that a return of less than the
    escape start sequence consumes only part (or none) of the start sequence.
    Raise an error for an invalid escape sequence.
    """

  fun octal(c: U8): Bool => (c >= '0') and (c <= '7')

  fun hex(c: U8): Bool =>
    ((c >= '0') and (c <= '9')) or
    ((c >= 'A') and (c <= 'F')) or
    ((c >= 'a') and (c <= 'f'))

  fun x_hex(source: String, offset: USize, x: USize): Bool ? =>
    for i in Range(0, x) do
      if not hex(source(offset + i)) then
        return false
      end
    end
    true

primitive PonyEscape is Escape
  fun start(): String => "\\"

  fun apply(source: String, offset: USize): USize ? =>
    match source(offset)
    | 'a' | 'b' | 'e' | 'f' | 'n' | 'r' | 't' | 'v'
    | '\\' | '\'' | '"' | '0' => 2
    | 'x' if x_hex(source, offset, 2) => 4
    | 'u' if x_hex(source, offset, 4) => 6
    | 'U' if x_hex(source, offset, 6) => 8
    else
      error
    end

primitive CEscape is Escape
  fun start(): String => "\\"

  fun apply(source: String, offset: USize): USize ? =>
    match source(offset)
    | 'a' | 'b' | 'e' | 'f' | 'n' | 'r' | 't' | 'v'
    | '\\' | '\'' | '"' | '?' => 2
    | 'x' if x_hex(source, offset, 2) => 4
    | 'u' if x_hex(source, offset, 4) => 6
    | 'U' if x_hex(source, offset, 8) => 10
    else
      if octal(source(offset + 1)) then
        if ((offset + 2) < source.size()) and octal(source(offset + 2)) then
          if ((offset + 3) < source.size()) and octal(source(offset + 3)) then 
            4
          else 3 end
        else 2 end
      else error end
    end

primitive TripleEscape is Escape
  fun start(): String => "\""

  fun apply(source: String, offset: USize): USize ? =>
    """
    A triple quoted string can end with more than 3 " characters. If so, the
    addition " characters are part of the string.
    """
    var advance = USize(0)
    while source(offset + advance) == '"' do
      advance = advance + 1
    end

    if advance >= 2 then
      advance - 2
    else
      advance + 1
    end

trait QuoteString[E: Escape] is StringTerminal[E]
  fun start(): String => "'"
  fun finish(): String => "'"

trait DblQuoteString[E: Escape] is StringTerminal[E]
  fun start(): String => "\""
  fun finish(): String => "\""

primitive CString is DblQuoteString[CEscape]
primitive PonyString is DblQuoteString[PonyEscape]

primitive TripleQuoteString is StringTerminal[TripleEscape]
  fun start(): String => "\"\"\""
  fun finish(): String => "\"\"\""
*/
