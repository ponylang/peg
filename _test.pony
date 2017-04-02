use "files"

actor Main
  new create(env: Env) =>
    let p = JsonParser()

    // TODO: Errors should be based on the longest successful match
    // TODO: Restart: ability to record errors then skip ahead to some token
    // to continue parsing from there
    // TODO: reorder AST nodes after parsing a Sequence?

    try
      with file = OpenFile(
        FilePath(env.root as AmbientAuth, env.args(1))) as File
      do
        let source: String = file.read_string(file.size())
        (let adv, let r) = p.parse(source, 0, true, NoParser)
        match r
        | let ast: AST => ast.print(env.out)
        | let token: Token => token.print(env.out)
        | ParseFail => env.out.print("Parse fail")
        end
      end
    else
      env.out.print("Couldn't open source file")
    end
