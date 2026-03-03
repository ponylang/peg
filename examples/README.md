# Examples

Each entry demonstrates a different aspect of the peg library. Build all
examples with `make build-examples`.

## [compiler](compiler/)

A CLI tool that parses files using the library's built-in parsers or a
custom-compiled grammar. With one argument, it auto-detects whether the
input is JSON or PEG and prints the parse tree. With two arguments, it
compiles the first file as a PEG grammar and uses it to parse the second.
Demonstrates `JsonParser`, `PegParser`, `PegCompiler`, `Source`, `Printer`,
and `PegFormatError`. Start here if you're new to the library.

## [json.peg](json.peg)

A JSON parser written in PEG file syntax. Shows the full range of PEG
operators including the `-` (skip), `%` (separated list), and `?`
(optional) extensions. Feed it to the compiler example to parse JSON
files: `./compiler json.peg some_file.json`.

## [peg.peg](peg.peg)

A self-describing PEG grammar — a grammar that parses `.peg` files,
written as a `.peg` file itself. Useful as a quick reference for the
PEG file syntax and operator set.
