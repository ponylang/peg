trait val Label
  """
  A label identifies AST nodes and tokens in the parse tree. Define custom
  labels as primitives implementing this trait to tag your grammar's rules.
  """
  fun text(): String
    """
    The label's display text.
    """

primitive NoLabel is Label
  """
  The default empty label, used when no label has been assigned.
  """
  fun text(): String =>
    """
    Return the empty string.
    """
    ""
