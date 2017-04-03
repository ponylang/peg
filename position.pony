use "collections"

primitive Position
  fun apply(source: String, offset: USize): (USize, USize) =>
    var cr = false
    var line = USize(1)
    var col = USize(1)

    try
      for i in Range(0, offset) do
        match source(i)
        | '\r' =>
          line = line + 1
          col = 1
          cr = true
        | '\n' =>
          if not cr then
            line = line + 1
            col = 1
          else
            cr = false
          end
        else
          col = col + 1
          cr = false
        end
      end
    end

    (line, col)

  fun source_line(source: String, offset: USize, line: USize, col: USize)
    : String
  =>
    let start = ((offset - col) + 1).isize()
    let finish = try source.find("\n", start) else source.size().isize() end
    source.substring(start, finish)
