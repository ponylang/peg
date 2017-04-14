use "files"

actor Main
  new create(env: Env) =>
    // TODO: Restart: ability to record errors then skip ahead to some token
    // to continue parsing from there
    // TODO: reorder AST nodes after parsing a Sequence?
    // TODO: attach lambdas to rules?
    // TODO: keywords have to make sure they aren't followed by an identifier character

    try
      if env.args.size() >= 3 then
        peg_compiler(env)
      else
        let auth = env.root as AmbientAuth
        let filename = env.args(1)
        let p = (JsonParser() / PegParser()).eof()
        peg_run(p, filename, auth, env.out)
      end
    end

  fun peg_run(p: Parser, filename: String, auth: AmbientAuth, out: OutStream) =>
    """
    Run a parser over some source file and print the AST.
    """
    try
      with file = OpenFile(FilePath(auth, filename)) as File do
        let source: String = file.read_string(file.size())
        match p.parse(source)
        | (_, let r: ASTChild) =>
          out.print(recover val Printer(r) end)
        | (let offset: USize, let r: Parser) =>
          out.writev(Error(filename, source, offset, r))
        end
      end
    else
      out.print("Couldn't open file " + filename)
    end

  fun peg_compiler(env: Env) =>
    """
    Compile a parser from the first file, then run it over the second file and
    print the AST.
    """
    try
      let peg_filename = env.args(1)
      let source_filename = env.args(2)
      let auth = env.root as AmbientAuth

      with
        peg_file = OpenFile(FilePath(auth, peg_filename)) as File
      do
        let peg: String = peg_file.read_string(peg_file.size())

        match recover val PegCompiler(peg) end
        | let p: Parser val =>
          peg_run(p, source_filename, auth, env.out)
        | let errors: Errors val =>
          for e in errors.values() do
            env.out.writev(e)
          end
        end
      end
    end
