## Update to work with ponyc 0.61.1

ponyc 0.61.1 now detects exhaustive match blocks and treats unreachable `else` clauses as compile errors. peg has been updated to remove these unreachable `else` clauses, which means peg now requires ponyc 0.61.1 or newer.

