use "files"

class val Source
  """
  Wraps source text for parsing. Create from a file path with `Source(path)?`
  or from a string with `Source.from_string(text)`.
  """
  let path: String
  let content: String

  new val create(filepath: FilePath) ? =>
    """Load source text from a file. Errors if the file cannot be opened."""
    path = filepath.path
    let file = OpenFile(filepath) as File
    content = file.read_string(file.size())
    file.dispose()

  new val from_string(content': String, path': String = "") =>
    """Create source from an in-memory string."""
    (path, content) = (path', content')
