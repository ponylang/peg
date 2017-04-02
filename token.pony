use "collections"

primitive NoToken
primitive EOF

class val Token
  let label: Label
  let source: String
  let offset: USize
  let length: USize

  new val create(label': Label, source': String, offset': USize, length': USize)
  =>
    label = label'
    source = source'
    offset = offset'
    length = length'

  fun print(out: OutStream) =>
    out.print(source.substring(offset.isize(), (offset + length).isize()))

  fun position(): (USize, USize) =>
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
