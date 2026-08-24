## Fix skip inside terminal producing empty tokens

When a skip operator (`-e`) appeared inside a terminal (`.term()`), the terminal silently produced an empty token instead of advancing past the skipped content. For example, `(-L("[") * R('a', 'z').many1() * -L("]")).term(MyLabel)` applied to `[hello]` would yield an empty token rather than a token spanning the full match.

Skip inside a terminal now advances past the matched content, and the resulting token spans the entire matched region including the skipped bytes.
