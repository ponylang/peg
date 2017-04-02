use "files"

actor Main
  new create(env: Env) =>
    let p = JsonParser()

    // TODO: Errors should be based on the longest successful match
    // TODO: Restart: ability to record errors then skip ahead to some token
    // to continue parsing from there
    // TODO: reorder AST nodes after parsing a Sequence?
    // TODO: check for hidden+EOF when finishing a parse

    try
      with file = OpenFile(
        FilePath(env.root as AmbientAuth, env.args(1))) as File
      do
        let source: String = file.read_string(file.size())
        (let adv, let r) = recover val p.parse(source) end
        match r
        | let r': (AST | Token | NotPresent) =>
          let s = recover val Printer(r') end
          env.out.print(s)
        | ParseFail => env.out.print("Parse fail")
        end
      end
    else
      env.out.print("Couldn't open source file")
    end
