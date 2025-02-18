# Notes

- Lox has semicolons. One of the boundaries we check when trying to synchronize after hitting a parsing error is a `;` could we do the same with newlines if we chose not to end lines with semicolons?
- in the grammar `assignment  -> IDENTIFIER "=" assignment | equality; `, does this mean that we can do things like `a = b = 42`?

# Current Progress

I'm able to define a function, but it's not being called.

It looks like it could be a parser error. I don't seem to be entering the "call" method in the parser for the function call.  It seems to just be registering as an expression.
