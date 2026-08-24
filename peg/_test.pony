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
