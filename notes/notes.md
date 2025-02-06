# Notes

- Lox has semicolons. One of the boundaries we check when trying to synchronize after hitting a parsing error is a `;` could we do the same with newlines if we chose not to end lines with semicolons?
- in the grammar `assignment  -> IDENTIFIER "=" assignment | equality; `, does this mean that we can do things like `a = b = 42`?

# Current Progress

Just implemented `while` but it doesn't seem like I'm re-assessing the conditional after each loop, so it looks like it's stuck in an infintite loop.
