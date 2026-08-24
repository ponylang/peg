use "files"
use "pony_test"

actor \nodoc\ Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_TestFromFile("json", "json_test.json", "json_out.txt"))
    test(_TestSkipInSequenceTerminal)
    test(_TestSkipInManyTerminal)
    test(_TestSkipInChoiceTerminal)
    test(_TestManyNotTerminates)
    test(_TestManyNotTreeTerminates)
    test(_TestManyOptTerminates)
    test(_TestManyOptTreeTerminates)
    test(_TestMany1NotTerminates)
    test(_TestMany1NotTreeTerminates)
    test(_TestMany1OptTerminates)
    test(_TestMany1OptTreeTerminates)

class \nodoc\ iso _TestFromFile is UnitTest
  let _example: String
  let _test: String
  let _expect: String

  new iso create(example: String, test: String, expect: String) =>
    (_example, _test, _expect) = (example, test, expect)

  fun name(): String =>
    _example

  fun apply(h: TestHelper) ? =>
    let auth = FileAuth(h.env.root)
    let peg_file = FilePath(auth, "examples/" + _example + ".peg")
    let test_file = FilePath(auth, "test/" + _test)
    let expect_file = FilePath(auth, "test/" + _expect)
    match \exhaustive\ recover val PegCompiler(Source(peg_file)?) end
    | let p: Parser val =>
      let out = peg_run(h, p, Source(test_file)?)?
      with file = OpenFile(expect_file) as File do
        h.assert_eq[String](file.read_string(file.size()), out)
      end
    | let errors: Array[PegError] val =>
      for e in errors.values() do
        h.env.err.printv(PegFormatError.console(e))
      end
    end

  fun peg_run(h: TestHelper, p: Parser val, source: Source): String ? =>
    match recover val p.parse(source) end
    | (_, let r: ASTChild) => recover Printer(r) end
    | (let offset: USize, let r: Parser val) =>
      let e = recover val SyntaxError(source, offset, r) end
      h.env.out.writev(PegFormatError.console(e))
      error
    else error
    end

primitive \nodoc\ _TestLabel is Label
  fun text(): String => "Test"

class \nodoc\ iso _TestSkipInSequenceTerminal is UnitTest
  """
  A terminal whose inner parser is a sequence with skip operators produces a
  token spanning the full match, including the skipped content.
  """
  fun name(): String =>
    "skip in sequence terminal"

  fun apply(h: TestHelper) =>
    let src = Source.from_string("[hello]", "test")
    let p: Parser val =
      recover val
        (-L("[") * R('a', 'z').many1() * -L("]")).term(_TestLabel)
      end
    match recover val p.parse(src) end
    | (let n: USize, let t: Token) =>
      h.assert_eq[USize](7, n)
      h.assert_eq[String]("Test", t.label().text())
      h.assert_eq[String]("[hello]", t.string())
    else
      h.fail("expected a Token result")
    end

class \nodoc\ iso _TestSkipInManyTerminal is UnitTest
  """
  A terminal whose inner parser uses repetition with skip operators produces a
  token spanning the full match, including the skipped content.
  """
  fun name(): String =>
    "skip in many terminal"

  fun apply(h: TestHelper) =>
    let src = Source.from_string("\n\nabc", "test")
    let p: Parser val =
      recover val
        ((-L("\n")).many1() * R('a', 'z').many1()).term(_TestLabel)
      end
    match recover val p.parse(src) end
    | (let n: USize, let t: Token) =>
      h.assert_eq[USize](5, n)
      h.assert_eq[String]("Test", t.label().text())
      h.assert_eq[String]("\n\nabc", t.string())
    else
      h.fail("expected a Token result")
    end

class \nodoc\ iso _TestSkipInChoiceTerminal is UnitTest
  """
  A terminal whose inner parser is a choice returning a skip operator produces
  a token spanning the skipped content.
  """
  fun name(): String =>
    "skip in choice terminal"

  fun apply(h: TestHelper) =>
    let src = Source.from_string("[", "test")
    let p: Parser val =
      recover val
        (-L("[") / L("(")).term(_TestLabel)
      end
    match recover val p.parse(src) end
    | (let n: USize, let t: Token) =>
      h.assert_eq[USize](1, n)
      h.assert_eq[String]("Test", t.label().text())
      h.assert_eq[String]("[", t.string())
    else
      h.fail("expected a Token result")
    end

class \nodoc\ iso _TestManyNotTerminates is UnitTest
  """
  `Not` inside `Many` returns a zero-advance success when the inner parser
  fails to match. In token mode, `Many` breaks instead of looping forever.
  """
  fun name(): String =>
    "many with not terminates in token mode"

  fun apply(h: TestHelper) =>
    let src = Source.from_string("abc", "test")
    let p: Parser val = recover val L("x").op_not().many() end
    match recover val p.parse(src, 0, false) end
    | (let n: USize, Lex) =>
      h.assert_eq[USize](0, n)
    else
      h.fail("expected (0, Lex)")
    end

class \nodoc\ iso _TestManyNotTreeTerminates is UnitTest
  """
  `Not` inside `Many` returns a zero-advance success when the inner parser
  fails to match. In tree mode, `Many` breaks instead of looping forever.
  """
  fun name(): String =>
    "many with not terminates in tree mode"

  fun apply(h: TestHelper) =>
    let src = Source.from_string("abc", "test")
    let p: Parser val = recover val L("x").op_not().many() end
    match recover val p.parse(src) end
    | (let n: USize, let a: AST) =>
      h.assert_eq[USize](0, n)
      h.assert_eq[USize](0, a.size())
    else
      h.fail("expected (0, empty AST)")
    end

class \nodoc\ iso _TestManyOptTerminates is UnitTest
  """
  `Option` inside `Many` returns a zero-advance `NotPresent` when the inner
  parser fails to match. In token mode, `Many` breaks instead of looping
  forever.
  """
  fun name(): String =>
    "many with option terminates in token mode"

  fun apply(h: TestHelper) =>
    let src = Source.from_string("abc", "test")
    let p: Parser val = recover val L("x").opt().many() end
    match recover val p.parse(src, 0, false) end
    | (let n: USize, Lex) =>
      h.assert_eq[USize](0, n)
    else
      h.fail("expected (0, Lex)")
    end

class \nodoc\ iso _TestManyOptTreeTerminates is UnitTest
  """
  `Option` inside `Many` returns a zero-advance `NotPresent` when the inner
  parser fails to match. In tree mode, `Many` breaks instead of looping
  forever.
  """
  fun name(): String =>
    "many with option terminates in tree mode"

  fun apply(h: TestHelper) =>
    let src = Source.from_string("abc", "test")
    let p: Parser val = recover val L("x").opt().many() end
    match recover val p.parse(src) end
    | (let n: USize, let a: AST) =>
      h.assert_eq[USize](0, n)
      h.assert_eq[USize](0, a.size())
    else
      h.fail("expected (0, empty AST)")
    end

class \nodoc\ iso _TestMany1NotTerminates is UnitTest
  """
  `many1` with a zero-advance `Not` terminates and reports failure. In token
  mode, the loop breaks on zero advance, then the `_require` check returns a
  parse error because no elements were consumed.
  """
  fun name(): String =>
    "many1 with not terminates in token mode"

  fun apply(h: TestHelper) =>
    let src = Source.from_string("abc", "test")
    let p: Parser val = recover val L("x").op_not().many1() end
    match recover val p.parse(src, 0, false) end
    | (let n: USize, let r: Parser) =>
      h.assert_eq[USize](0, n)
    else
      h.fail("expected (0, Parser)")
    end

class \nodoc\ iso _TestMany1NotTreeTerminates is UnitTest
  """
  `many1` with a zero-advance `Not` terminates and reports failure. In tree
  mode, the loop breaks on zero advance, then the `_require` check returns a
  parse error because no elements were consumed.
  """
  fun name(): String =>
    "many1 with not terminates in tree mode"

  fun apply(h: TestHelper) =>
    let src = Source.from_string("abc", "test")
    let p: Parser val = recover val L("x").op_not().many1() end
    match recover val p.parse(src) end
    | (let n: USize, let r: Parser) =>
      h.assert_eq[USize](0, n)
    else
      h.fail("expected (0, Parser)")
    end

class \nodoc\ iso _TestMany1OptTerminates is UnitTest
  """
  `many1` with a zero-advance `Option` terminates and reports failure. In
  token mode, the loop breaks on zero advance, then the `_require` check
  returns a parse error because no elements were consumed.
  """
  fun name(): String =>
    "many1 with option terminates in token mode"

  fun apply(h: TestHelper) =>
    let src = Source.from_string("abc", "test")
    let p: Parser val = recover val L("x").opt().many1() end
    match recover val p.parse(src, 0, false) end
    | (let n: USize, let r: Parser) =>
      h.assert_eq[USize](0, n)
    else
      h.fail("expected (0, Parser)")
    end

class \nodoc\ iso _TestMany1OptTreeTerminates is UnitTest
  """
  `many1` with a zero-advance `Option` terminates and reports failure. In
  tree mode, the loop breaks on zero advance, then the `_require` check
  returns a parse error because no elements were consumed.
  """
  fun name(): String =>
    "many1 with option terminates in tree mode"

  fun apply(h: TestHelper) =>
    let src = Source.from_string("abc", "test")
    let p: Parser val = recover val L("x").opt().many1() end
    match recover val p.parse(src) end
    | (let n: USize, let r: Parser) =>
      h.assert_eq[USize](0, n)
    else
      h.fail("expected (0, Parser)")
    end
