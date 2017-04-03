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
