## Add support for not colorizing the terminal output

Prior to this change any error message called via `PegFormatError.console`
would return an error message with ANSI escape sequence code for coloring. This
created a problem when piping the output to something other than a terminal.

This change adds the ability to remove ANSI escape sequence codes from the
output. The change is non-breaking as the default behavior is to colorize
the output. The colorization can be turned off by supplying `false` to
the `colorize` parameter:

```pony
PegFormatError.console(error, false)
```

