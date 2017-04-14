use "collections"

type Defs is Map[String, Forward]
type Errors is ReadSeq[ByteSeqIter box] box
type ErrorAccum is Array[ByteSeqIter box]

primitive PegCompiler
  fun apply(source: String): (Parser | Errors) =>
    let p: Parser = PegParser().eof()
    match p.parse(source)
    | (_, let ast: AST) =>
      _compile_grammar(ast)
    | (let offset: USize, let r: Parser) =>
      [ Error("...", source, offset, r) ]
    else
      [["Unreachable parse result\n"]]
    end

  fun _compile_grammar(ast: AST): (Parser | Errors) =>
    let defs = Defs
    let errors = ErrorAccum
    defs("start") = Forward

    for node in ast.children.values() do
      try _compile_definition(errors, defs, node as AST) end
    end

    for (rule, def) in defs.pairs() do
      if not def.complete() then
        // TODO: emit error for undefined rule
        errors.push(["Undefined rule "; rule; "\n"])
      end
    end

    if errors.size() == 0 then
      try
        var start: Parser = defs("start")
        if defs.contains("hidden") then
          start = start.hide(defs("hidden"))
        end
        return start
      end
    end

    errors

  fun _compile_definition(errors: ErrorAccum, defs: Defs, ast: AST) =>
    try
      let ident: String = (ast.children(0) as Token).string()
      let expr = ast.children(1)
      let p = defs.insert_if_absent(ident, Forward)

      if not p.complete() then
        let rule = _compile_expr(errors, defs, expr)
        let c = ident(0)
        if (c >= 'A') and (c <= 'Z') then
          p() = rule.term(PegLabel(ident))
        else
          p() =
            match rule
            | let rule': Sequence => rule'.node(PegLabel(ident))
            | let rule': Many => rule'.node(PegLabel(ident))
            else
              rule
            end
        end
      else
        // TODO: emit error for double definition
        errors.push(["Double definition of "; ident; "\n"])
      end
    end

  fun _compile_expr(errors: ErrorAccum, defs: Defs, node: ASTChild)
    : (Parser ref | NoParser)
  =>
    try
      match node.label()
      | PegChoice =>
        let ast = node as AST
        var p = _compile_expr(errors, defs, ast.children(0))
        for i in Range(1, ast.children.size()) do
          p = p / _compile_expr(errors, defs, ast.children(i))
        end
        p
      | PegSeq =>
        let ast = node as AST
        var p = _compile_expr(errors, defs, ast.children(0))
        for i in Range(1, ast.children.size()) do
          p = p * _compile_expr(errors, defs, ast.children(i))
        end
        p
      | PegSkip =>
        -_compile_expr(errors, defs, (node as AST).children(0))
      | PegNot =>
        not _compile_expr(errors, defs, (node as AST).children(0))
      | PegAnd =>
        not not _compile_expr(errors, defs, (node as AST).children(0))
      | PegMany1 =>
        _compile_expr(errors, defs, (node as AST).children(0)).many1()
      | PegMany =>
        _compile_expr(errors, defs, (node as AST).children(0)).many()
      | PegSep1 =>
        let ast = node as AST
        let sep = _compile_expr(errors, defs, ast.children(1))
        _compile_expr(errors, defs, ast.children(0)).many1(sep)
      | PegSep =>
        let ast = node as AST
        let sep = _compile_expr(errors, defs, ast.children(1))
        _compile_expr(errors, defs, ast.children(0)).many(sep)
      | PegOpt =>
        _compile_expr(errors, defs, (node as AST).children(0)).opt()
      | PegRange =>
        let ast = node as AST
        let a = _unescape(ast.children(0) as Token).utf32(0)._1
        let b = _unescape(ast.children(1) as Token).utf32(0)._1
        R(a, b)
      | PegIdent =>
        defs.insert_if_absent((node as Token).string(), Forward)
      | PegAny =>
        R(' ')
      | PegChar =>
        let text = _unescape(node as Token)
        L(text).term(PegLabel(text))
      | PegString =>
        let text = _unescape(node as Token)
        L(text).term(PegLabel(text))
      else
        errors.push(["Unknown node label "; node.label().text(); "\n"])
        NoParser
      end
    else
      errors.push(["Unknown error\n"])
      NoParser
    end

  fun _unescape(token: Token): String =>
    recover
      let out = String
      var escape = false
      var hex = USize(0)
      var hexrune = U32(0)

      for rune in token.substring(1, -1).runes() do
        if escape then
          match rune
          | '0' => out.append("\0")
          | '"' => out.append("\"")
          | '\\' => out.append("\\")
          | 'a' => out.append("\a")
          | 'b' => out.append("\b")
          | 'f' => out.append("\f")
          | 'n' => out.append("\n")
          | 'r' => out.append("\r")
          | 't' => out.append("\t")
          | 'v' => out.append("\v")
          | '\'' => out.append("'")
          | 'x' => hex = 2
          | 'u' => hex = 4
          | 'U' => hex = 6
          end
        elseif rune == '\\' then
          escape = true
        elseif hex > 0 then
          hexrune = (hexrune << 8) or match rune
          | if (rune >= '0') and (rune <= '9') => rune - '0'
          | if (rune >= 'a') and (rune <= 'f') => (rune - 'a') + 10
          else (rune - 'A') + 10 end
          if (hex = hex - 1) == 1 then
            out.push_utf32(hexrune = 0)
          end
        else
          out.push_utf32(rune)
        end
      end

      out
    end

class val PegLabel is Label
  let _text: String

  new val create(text': String) =>
    _text = text'
  
  fun text(): String => _text
