primitive Unicode is Parser
  fun parse(source: String, offset: USize, tree: Bool, hidden: Parser)
    : ParseResult
  =>
    let from = skip_hidden(source, offset, hidden)
    try
      (let c, let length) = source.utf32(from.isize())
      if c != 0xFFFD then
        return result(source, offset, from, length.usize(), tree)
      end
    end
    (0, ParseFail)

type R is UnicodeRange

class box UnicodeRange is Parser
  let _low: U32
  let _hi: U32

  new create(low: U32, hi: U32 = 0x10FFFF) =>
    _low = low
    _hi = hi

  fun parse(source: String, offset: USize, tree: Bool, hidden: Parser)
    : ParseResult
  =>
    let from = skip_hidden(source, offset, hidden)
    try
      (let c, let length) = source.utf32(from.isize())
      if (c != 0xFFFD) and (c >= _low) and (c <= _hi) then
        return result(source, offset, from, length.usize(), tree)
      end
    end
    (0, ParseFail)
