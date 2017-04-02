use "collections" // TODO: we pick up Range from a trait, and then need this

primitive JsonParser
  fun apply(): Parser =>
    let obj = Forward
    let array = Forward

    let digit19 =
      L("1") / L("2") / L("3") / L("4") / L("5") /
      L("6") / L("7") / L("8") / L("9")
    let digit = L("0") / digit19
    let digits = digit.many1()
    let int =
      (L("-") * digit19 * digits) /
      (L("-") * digit) /
      (digit19 * digits) /
      (digit)
    let frac = L(".") * digits
    let exp = (L("e") / L("E")) * (L("+") / L("-")).opt() * digits
    let number = (int * frac.opt() * exp.opt()).term()

    let hex =
      digit /
      L("a") / L("b") / L("c") / L("d") / L("e") / L("f") /
      L("A") / L("B") / L("C") / L("D") / L("E") / L("F")

    let char =
      L("\\\"") / L("\\\\") / L("\\/") / L("\\b") / L("\\f") / L("\\n") /
      L("\\r") / L("\\t") / (L("\\u") * hex * hex * hex * hex) /
      (not L("\"") * not L("\\") * Character)
      // TODO: exclude control characters?
      // TODO: rewrite Character as a range?

    // TODO: labels
    // TODO: get the shape of the parse tree right
    let string = (L("\"") * char.many() * L("\"")).term()
    let value =
      L("null") / L("true") / L("false") / number / string / obj / array

    let pair = string * L(":").skip() * value
    let members = (pair * (L(",").skip() * pair).many()).opt()
    let elements = (value * (L(",").skip() * value).many()).opt()

    obj() = L("{").skip() * members * L("}").skip()
    array() = L("[").skip() * elements * L("]").skip()

    let whitespace = (L(" ") / L("\t") / L("\r") / L("\n")).many1()
    value.hide(whitespace)
