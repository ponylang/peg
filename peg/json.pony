primitive JsonParser
  """
  A JSON parser built from combinators. Supports standard JSON plus `//`, `#`,
  and `/* ... */` comments (nested). The parse tree uses `TObject`, `TPair`,
  `TArray`, `TString`, `TNumber`, `TBool`, and `TNull` labels.
  """
  fun apply(): Parser val =>
    recover
      let obj = Forward
      let array = Forward

      let digit19 = R('1', '9')
      let digit = R('0', '9')
      let digits = digit.many1()
      let int =
        (L("-") * digit19 * digits) / (L("-") * digit) /
        (digit19 * digits) / digit
      let frac = L(".") * digits
      let exp = (L("e") / L("E")) * (L("+") / L("-")).opt() * digits
      let number = (int * frac.opt() * exp.opt()).term(TNumber)

      let hex = digit / R('a', 'f') / R('A', 'F')
      let char =
        L("\\\"") / L("\\\\") / L("\\/") / L("\\b") / L("\\f") / L("\\n") /
        L("\\r") / L("\\t") / (L("\\u") * hex * hex * hex * hex) /
        (not L("\"") * not L("\\") * R(' '))

      let string = (L("\"") * char.many() * L("\"")).term(TString)
      let value =
        L("null").term(TNull) / L("true").term(TBool) / L("false").term(TBool) /
        number / string / obj / array
      let pair = (string * -L(":") * value).node(TPair)
      obj() = -L("{") * pair.many(L(",")).node(TObject) * -L("}")
      array() = -L("[") * value.many(L(",")).node(TArray) * -L("]")

      let whitespace = (L(" ") / L("\t") / L("\r") / L("\n")).many1()
      let linecomment =
        (L("#") / L("//")) * (not L("\r") * not L("\n") * Unicode).many()
      let nestedcomment = Forward
      nestedcomment() =
        L("/*") *
        ((not L("/*") * not L("*/") * Unicode) / nestedcomment).many() *
        L("*/")
      let hidden = (whitespace / linecomment / nestedcomment).many()

      value.hide(hidden)
    end

// AST labels for the JSON parser. Match on these when processing JSON parse
// results.

// A JSON object `{...}` containing zero or more `TPair` children.
primitive TObject is Label fun text(): String => "Object"
// A key-value pair in a JSON object: children are `TString` and a value.
primitive TPair is Label fun text(): String => "Pair"
// A JSON array `[...]` containing zero or more value children.
primitive TArray is Label fun text(): String => "Array"
// A JSON string value (including the surrounding quotes in the token).
primitive TString is Label fun text(): String => "String"
// A JSON number value.
primitive TNumber is Label fun text(): String => "Number"
// A JSON boolean (`true` or `false`).
primitive TBool is Label fun text(): String => "Bool"
// A JSON `null` value.
primitive TNull is Label fun text(): String => "Null"
