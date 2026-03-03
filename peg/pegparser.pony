primitive PegParser
  """
  The built-in parser for `.peg` grammar files. Used internally by
  `PegCompiler` to parse grammar source before compilation. Supports
  `//`, `#`, and `/* ... */` comments (nested).
  """
  fun apply(): Parser val =>
    recover
      let digit = R('0', '9')
      let hex = digit / R('a', 'f') / R('A', 'F')
      let char =
        L("\\0") / L("\\\"") / L("\\\\") /
        L("\\a") / L("\\b") / L("\\f") / L("\\n") /
        L("\\r") / L("\\t") / L("\\v") / L("\\'") / 
        (L("\\x") * hex * hex) /
        (L("\\u") * hex * hex * hex * hex) /
        (L("\\U") * hex * hex * hex * hex * hex * hex) /
        (not L("\"") * not L("\\") * R(' '))

      let string = (L("\"") * char.many() * L("\"")).term(PegString)
      let charlit = (L("'") * char * L("'")).term(PegChar)
      let dot = L(".").term(PegAny)

      let ident_start = R('a', 'z') / R('A', 'Z') / L("_")
      let ident_cont = ident_start / R('0', '9')
      let ident = (ident_start * ident_cont.many()).term(PegIdent)
      let range = (charlit * -L("..") * charlit).node(PegRange)

      let expr = Forward
      let group = -L("(") * expr * -L(")")
      let primary =
        (ident * not L("<-")) / group / range / string / charlit / dot
      let suffix =
        (primary * -L("?")).node(PegOpt) /
        (primary * -L("*")).node(PegMany) /
        (primary * -L("+")).node(PegMany1) /
        (primary * -L("%+") * primary).node(PegSep1) /
        (primary * -L("%") * primary).node(PegSep) /
        primary
      let prefix =
        (-L("&") * suffix).node(PegAnd) /
        (-L("!") * suffix).node(PegNot) /
        (-L("-") * suffix).node(PegSkip) /
        suffix
      let sequence = prefix.many1().node(PegSeq)
      expr() = sequence.many1(L("/")).node(PegChoice)
      let definition = (ident * -L("<-") * expr).node(PegDef)

      let whitespace = (L(" ") / L("\t") / L("\r") / L("\n")).many1()
      let linecomment =
        (L("#") / L("//")) * (not L("\r") * not L("\n") * Unicode).many()
      let nestedcomment = Forward
      nestedcomment() =
        L("/*") *
        ((not L("/*") * not L("*/") * Unicode) / nestedcomment).many() *
        L("*/")
      let hidden = (whitespace / linecomment / nestedcomment).many()
      definition.many1().node(PegGrammar).hide(hidden)
    end

// AST labels for the PEG grammar parser. These are internal labels used by
// PegParser and PegCompiler to represent the structure of a .peg file's AST.

// A quoted string literal in a PEG grammar.
primitive PegString is Label fun text(): String => "String"
// A single-quoted character literal in a PEG grammar.
primitive PegChar is Label fun text(): String => "Char"
// The `.` (any character) operator in a PEG grammar.
primitive PegAny is Label fun text(): String => "Any"
// A rule name reference in a PEG grammar.
primitive PegIdent is Label fun text(): String => "Ident"
// A character range (`'a'..'z'`) in a PEG grammar.
primitive PegRange is Label fun text(): String => "Range"
// An optional (`?`) expression in a PEG grammar.
primitive PegOpt is Label fun text(): String => "Opt"
// A zero-or-more (`*`) expression in a PEG grammar.
primitive PegMany is Label fun text(): String => "Many"
// A one-or-more (`+`) expression in a PEG grammar.
primitive PegMany1 is Label fun text(): String => "Many1"
// A separated list (`%`) expression in a PEG grammar.
primitive PegSep is Label fun text(): String => "Sep"
// A required separated list (`%+`) expression in a PEG grammar.
primitive PegSep1 is Label fun text(): String => "Sep1"
// An and-predicate (`&`) expression in a PEG grammar.
primitive PegAnd is Label fun text(): String => "And"
// A not-predicate (`!`) expression in a PEG grammar.
primitive PegNot is Label fun text(): String => "Not"
// A skip (`-`) expression in a PEG grammar.
primitive PegSkip is Label fun text(): String => "Skip"
// A sequence of expressions in a PEG grammar.
primitive PegSeq is Label fun text(): String => "Seq"
// An ordered choice (`/`) expression in a PEG grammar.
primitive PegChoice is Label fun text(): String => "Choice"
// A rule definition (`name <- expr`) in a PEG grammar.
primitive PegDef is Label fun text(): String => "Def"
// The top-level node containing all rule definitions.
primitive PegGrammar is Label fun text(): String => "Grammar"
