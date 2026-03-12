## Fix unreachable sep rule in self-describing PEG grammar

The `sep` rule (for the `%` separated-list-zero-or-more operator) was defined in `examples/peg.peg` but never referenced in `suffix`, making it unreachable. Only `%+` (one or more) was reachable via `sep1`. The `suffix` rule now includes `sep`.

## Update to work with ponyc 0.61.1

ponyc 0.61.1 now detects exhaustive match blocks and treats unreachable `else` clauses as compile errors. peg has been updated to remove these unreachable `else` clauses, which means peg now requires ponyc 0.61.1 or newer.

