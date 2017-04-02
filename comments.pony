trait LineComment is Parser
  """
  A line comment has some start text and then proceeds until a \r or \n.
  Comments don't appear in the token stream.
  """
  fun start(): String

  fun parse(source: String, offset: USize, tree: Bool, hidden: Parser)
    : ParseResult
  =>
    let offset' = skip_hidden(source, offset, hidden)
    let s = start()

    if source.at(s, offset'.isize()) then
      var length = s.size()

      while (offset' + length) < source.size() do
        try
          match source(offset' + length)
          | '\r' | '\n' => return result(source, offset', length, tree)
          else
            length = length + 1
          end
        end
      end
    end
    (0, ParseFail)

trait BlockComment is Parser
  """
  A block comment has some start text and then proceeds until the finish text.
  If the start text appears inside the block, it is ignored. Comments don't
  appear in the token stream.
  """
  fun start(): String
  fun finish(): String

  fun parse(source: String, offset: USize, tree: Bool, hidden: Parser)
    : ParseResult
  =>
    let offset' = skip_hidden(source, offset, hidden)
    let s = start()
    let f = finish()

    if source.at(s, offset'.isize()) then
      var length = s.size()

      while (offset' + length) < source.size() do
        if source.at(f, offset'.isize()) then
          return result(source, offset', length + f.size(), tree)
        else
          length = length + 1
        end
      end
    end
    (0, ParseFail)

trait NestedComment is Parser
  """
  A nested comment has some start text and then proceeds until the finish text.
  If the start text appears inside the block, it it treated as a nested comment
  that must also have finish text. Comments don't appear in the token stream.
  """
  fun start(): String
  fun finish(): String

  fun parse(source: String, offset: USize, tree: Bool, hidden: Parser)
    : ParseResult
  =>
    let offset' = skip_hidden(source, offset, hidden)
    let s = start()
    let f = finish()

    if source.at(s, offset'.isize()) then
      var length = s.size()
      var depth = USize(1)

      while true do
        if source.at(s, offset'.isize()) then
          depth = depth + 1
          length = length + s.size()
        elseif source.at(f, offset'.isize()) then
          depth = depth - 1
          length = length + f.size()
          
          if depth == 0 then
            return result(source, offset', length, tree)
          end
        else
          length = length + 1
        end
      end
    end
    (0, ParseFail)

primitive TwoSlashComment is LineComment fun start(): String => "//"
primitive TwoDashComment is LineComment fun start(): String => "--"
primitive HashComment is LineComment fun start(): String => "#"
primitive BangComment is LineComment fun start(): String => "!"

trait SlashStar
  fun start(): String => "/*"
  fun finish(): String => "*/"

primitive SlashStarBlock is (SlashStar & BlockComment)
primitive SlashStarNested is (SlashStar & NestedComment)

trait BraceDash
  fun start(): String => "{-"
  fun finish(): String => "-}"

primitive BraceDashBlock is (BraceDash & BlockComment)
primitive BraceDashNested is (BraceDash & NestedComment)

trait ParenStar
  fun start(): String => "(*"
  fun finish(): String => "*)"

primitive ParenStarBlock is (ParenStar & BlockComment)
primitive ParenStarNested is (ParenStar & NestedComment)
