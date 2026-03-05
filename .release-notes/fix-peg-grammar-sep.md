## Fix unreachable sep rule in self-describing PEG grammar

The `sep` rule (for the `%` separated-list-zero-or-more operator) was defined in `examples/peg.peg` but never referenced in `suffix`, making it unreachable. Only `%+` (one or more) was reachable via `sep1`. The `suffix` rule now includes `sep`.
