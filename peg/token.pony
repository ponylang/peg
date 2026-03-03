class val Token
  """
  A leaf node in the parse tree representing a span of matched source text.
  The token stores a reference to the source and the byte offset/length of
  the match rather than copying the text.
  """
  let _label: Label
  let source: Source
  let offset: USize
  let length: USize

  new val create(label': Label, source': Source, offset': USize, length': USize)
  =>
    _label = label'
    source = source'
    offset = offset'
    length = length'

  fun label(): Label =>
    """This token's label."""
    _label

  fun string(): String iso^ =>
    """The full matched text."""
    source.content.substring(offset.isize(), (offset + length).isize())

  fun substring(from: ISize, to: ISize): String iso^ =>
    """A substring of the matched text. Negative indices count from the end."""
    source.content.substring(
      offset_to_index(from).isize(), offset_to_index(to).isize())

  fun offset_to_index(i: ISize): USize =>
    """Convert a relative index to an absolute source position."""
    if i < 0 then offset + length + i.usize() else offset + i.usize() end
