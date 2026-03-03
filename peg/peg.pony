"""
# Peg Package

A Parsing Expression Grammar (PEG) library for Pony. It provides two ways to
define parsers: writing a `.peg` grammar file that is compiled at runtime, or
building parsers directly in Pony code using combinators.

## PEG File Mode

Write a grammar in a `.peg` file, then compile it with `PegCompiler`:

```pony
use "peg"
use "files"

actor Main
  new create(env: Env) =>
    try
      let auth = FileAuth(env.root)
      let source = Source(FilePath(auth, "my_grammar.peg"))?

      match recover val PegCompiler(source) end
      | let parser: Parser val =>
        let input = Source.from_string("some input text")
        match recover val parser.parse(input) end
        | (_, let ast: AST) => env.out.print(recover val Printer(ast) end)
        | (let offset: USize, let r: Parser val) =>
          let e = recover val SyntaxError(input, offset, r) end
          env.out.writev(PegFormatError.console(e))
        end
      | let errors: Array[PegError] val =>
        for e in errors.values() do
          env.out.writev(PegFormatError.console(e))
        end
      end
    end
```

Use PEG file mode when grammars are user-supplied, loaded from disk, or when
you want to iterate on the grammar without recompiling Pony code.

## Combinator Mode

Build parsers directly in Pony using `L` (literal), `R` (unicode range),
`Unicode`, and operators:

```pony
use "peg"

actor Main
  new create(env: Env) =>
    let digit = R('0', '9')
    let number = digit.many1().term(TNumber)
    let op = (L("+") / L("-") / L("*") / L("/")).term(TOp)
    let expr = (number * op * number).node(TExpr)
    let whitespace = (L(" ") / L("\t")).many1()
    let parser = recover val expr.hide(whitespace) end

    let source = Source.from_string("42 + 7")
    match recover val parser.parse(source) end
    | (_, let ast: AST) => env.out.print(recover val Printer(ast) end)
    | (let offset: USize, let r: Parser val) =>
      let e = recover val SyntaxError(source, offset, r) end
      env.out.writev(PegFormatError.console(e))
    end

primitive TNumber is Label fun text(): String => "Number"
primitive TOp is Label fun text(): String => "Op"
primitive TExpr is Label fun text(): String => "Expr"
```

Use combinator mode when the grammar is fixed at compile time and you want
full type safety and IDE support.

## PEG File Grammar Reference

Rules are defined as `name <- expression` and separated by whitespace.
Comments use `//`, `#`, or `/* ... */` (nested comments are supported).

### Operators

| Syntax | Name | Description |
|---|---|---|
| `"text"` | String literal | Matches the exact string |
| `'c'` | Character literal | Matches a single character |
| `.` | Any | Matches any character (codepoint >= space) |
| `'a'..'z'` | Range | Matches a character in the codepoint range |
| `e1 e2` | Sequence | Matches e1 followed by e2 |
| `e1 / e2` | Ordered choice | Tries e1 first, then e2 if e1 fails |
| `e?` | Option | Matches e or succeeds with nothing |
| `e*` | Zero or more | Matches e repeatedly (zero or more times) |
| `e+` | One or more | Matches e repeatedly (at least once) |
| `!e` | Not predicate | Succeeds (consuming nothing) if e fails |
| `&e` | And predicate | Succeeds (consuming nothing) if e matches |
| `-e` | Skip (extension) | Matches e but omits it from the parse tree |
| `e % sep` | Separated list (extension) | Zero or more e separated by sep |
| `e %+ sep` | Separated list (extension) | One or more e separated by sep |

The `-`, `%`, and `%+` operators are extensions beyond standard PEG.

### Reserved Rule Names

- `start` — required entry point; parsing begins here
- `hidden` — defines the whitespace/comment channel; tokens matching
  this rule are automatically skipped between other tokens

### Naming Convention

- **Uppercase** rule names (e.g. `NUMBER`, `STRING`) produce terminal tokens:
  the matched text becomes a single `Token` leaf node
- **Lowercase** rule names (e.g. `value`, `pair`) produce `AST` nodes with
  children

## Combinator API

The combinators mirror the PEG file operators:

| PEG file | Pony combinator |
|---|---|
| `"text"` / `'c'` | `L("text")` |
| `.` | `R(' ')` (`Unicode` matches all codepoints) |
| `'a'..'z'` | `R('a', 'z')` |
| `e1 e2` | `e1 * e2` |
| `e1 / e2` | `e1 / e2` |
| `e?` | `e.opt()` |
| `e*` | `e.many()` |
| `e+` | `e.many1()` |
| `!e` | `not e` |
| `&e` | `not not e` |
| `-e` | `-e` |
| `e % sep` | `e.many(sep)` |
| `e %+ sep` | `e.many1(sep)` |
| Terminal rule | `e.term(MyLabel)` |
| Non-terminal rule | `e.node(MyLabel)` (on `Sequence` or `Many`) |
| Hidden channel | `e.hide(hidden_parser)` |
| End of file | `e.eof()` |
| Recursive rule | `Forward` + `update()` |

## Parse Results

Calling `Parser.parse()` returns a `ParseResult`, which is
`(USize, (ParseOK | Parser))`:

- Success: the second element is one of:
  - `AST` — a labeled tree node with children
  - `Token` — a leaf node with matched source text
  - `NotPresent` — returned by `Option` when the optional parse is absent
  - `Skipped` — returned by `Skip` (and `Not` on success)
- Failure: the second element is the `Parser` that failed, and the `USize`
  is the byte offset where it failed. Wrap in `SyntaxError` and format
  with `PegFormatError.console()` for display.

## Forward References

Use `Forward` to create mutually recursive grammars. Create the `Forward`
first, use it in other rules, then assign the real rule with `update()`:

```pony
let expr = Forward
let group = -L("(") * expr * -L(")")
expr() = group / some_other_rule  // () is sugar for update()
```

## Built-in Parsers

- `JsonParser` — a JSON parser built from combinators, with comment support
- `PegParser` — the parser for `.peg` grammar files (used by `PegCompiler`)

See the `examples/` directory for a CLI tool that demonstrates both.
"""
