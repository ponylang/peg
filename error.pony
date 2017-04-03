use "term"
use "collections"

primitive Error
  fun apply(filename: String, source: String, offset: USize, parser: Parser)
    : Array[String] val
  =>
    (let line, let col) = Position(source, offset)
    let s = Position.source_line(source, offset, line, col)
    let s2 =
      recover val
        let s3 = String
        try
          for i in Range(0, col - 1) do
            if s(i) == '\t' then
              s3.append("\t")
            else
              s3.append(" ")
            end
          end
        end
        s3
      end

    recover
      [ ANSI.red()
        "-- SYNTAX ERROR -- "
        filename
        ":"
        line.string()
        ":"
        col.string()
        ANSI.reset()
        "\n\n"
        s
        "\n"
        ANSI.red()
        s2
        "^ expected "
        parser.error_msg()
        ANSI.reset()
        "\n\n"
      ]
    end
