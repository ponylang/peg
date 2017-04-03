use "files"
use "term"

actor Main
  new create(env: Env) =>
    let p = JsonParser().eof()

    // TODO: Errors should be based on the longest successful match
    // TODO: Restart: ability to record errors then skip ahead to some token
    // to continue parsing from there
    // TODO: reorder AST nodes after parsing a Sequence?
    // TODO: attach lambdas to rules?
    // TODO: write a PEG parser parser
    // TODO: keywords have to make sure they aren't followed by an identifier character

    try
      let filename = env.args(1)

      with file = OpenFile(
        FilePath(env.root as AmbientAuth, filename)) as File
      do
        let source: String = file.read_string(file.size())
        (let adv, let r) = p.parse(source)
        match r
        | let r': (AST | Token | NotPresent) =>
          let s = recover val Printer(r') end
          env.out.print(s)
        | let r': Parser =>
          (let line, let col) = Position(source, adv)
          env.out.writev(
            recover
              [ ANSI.red()
                filename
                ":"
                line.string()
                ":"
                col.string()
                "\n"
                ANSI.reset()
              ]
            end)
        end
      end
    else
      env.out.print("Couldn't open source file")
    end
