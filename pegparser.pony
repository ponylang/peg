primitive PegParser
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
      let range = charlit * -L("..") * (charlit, PegRange)

      let expr = Forward
      let group = -L("(") * expr * -L(")")
      let primary =
        (ident * not L("<-")) / group / range / string / charlit / dot
      let suffix =
        (primary * (-L("?"), PegOpt)) /
        (primary * (-L("*"), PegMany)) /
        (primary * (-L("+"), PegMany1)) /
        primary
      let prefix =
        (-L("&") * (suffix, PegAnd)) /
        (-L("!") * (suffix, PegNot)) /
        (-L("-") * (suffix, PegSkip)) /
        suffix
      let sequence = prefix.many1(NoParser, PegSeq)
      expr() = sequence.many1(L("/"), PegChoice)
      let definition = ident * -L("<-") * (expr, PegDef)

      let whitespace = (L(" ") / L("\t") / L("\r") / L("\n")).many1()
      let linecomment = L("#") * (not L("\r") * not L("\n") * Unicode).many()      
      let hidden = (whitespace / linecomment).many()
      definition.many1(NoParser, PegGrammar).hide(hidden)
    end

primitive PegString is Label fun text(): String => "String"
primitive PegChar is Label fun text(): String => "Char"
primitive PegAny is Label fun text(): String => "Any"
primitive PegIdent is Label fun text(): String => "Ident"
primitive PegRange is Label fun text(): String => "Range"
primitive PegOpt is Label fun text(): String => "Opt"
primitive PegMany is Label fun text(): String => "Many"
primitive PegMany1 is Label fun text(): String => "Many1"
primitive PegAnd is Label fun text(): String => "And"
primitive PegNot is Label fun text(): String => "Not"
primitive PegSkip is Label fun text(): String => "Skip"
primitive PegSeq is Label fun text(): String => "Seq"
primitive PegChoice is Label fun text(): String => "Choice"
primitive PegDef is Label fun text(): String => "Def"
primitive PegGrammar is Label fun text(): String => "Grammar"
