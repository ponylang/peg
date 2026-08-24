## Fix skip inside terminal producing empty tokens

When a skip operator (`-e`) appeared inside a terminal (`.term()`), the terminal silently produced an empty token instead of advancing past the skipped content. For example, `(-L("[") * R('a', 'z').many1() * -L("]")).term(MyLabel)` applied to `[hello]` would yield an empty token rather than a token spanning the full match.

Skip inside a terminal now advances past the matched content, and the resulting token spans the entire matched region including the skipped bytes.

## Fix Many looping forever when inner parser succeeds without advancing

`Many` looped forever when its inner parser returned a zero-advance success. Two parsers produce this: `Not` returns `(0, Skipped)` when its inner parser fails to match, and `Option` returns `(0, NotPresent)` when its inner parser fails to match. With the default separator (`NoParser`), the separator also returns a zero-advance success, so nothing in the loop state changed between iterations.

Reproducer: `L("x").op_not().many()` applied to any input where `"x"` doesn't appear at the current position. Also `L("x").opt().many()` under the same conditions. Both are reachable from `.peg` files: `(!e)*` compiles to `Not(e).many()`, and `(e?)*` compiles to `Option(e).many()`.

In tree mode, `Option` inside `Many` also caused unbounded memory growth: `NotPresent` is an `ASTChild`, so each iteration pushed it into the AST node.

`Many` now breaks out of the loop when the inner parser succeeds without consuming any input.

