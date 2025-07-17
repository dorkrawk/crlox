program     -> declaration* EOF;
declaration -> classDecl |funDecl | varDecl | statement;
classDecl   -> "class" IDENTIFIER ( "<" IDENTIFIER )? "{" function* "}" ;
funDecl     -> "fun" function;
function    -> IDENTIFIER "(" parameters? ")" block;
parameters  -> IDENTIFIER ( "," IDENTIFIER )*;
varDecl     -> "var" IDENTIFIER ( "=" expression)? ";";
statement   -> exprStmt | 
                ifStmt | 
                forStmt |
                printStmt |
                returnStmt |
                whileStmt | 
                block;
exprStmt    -> expression ";";
ifStmt      -> "if" "(" expression ")" statement ( "else" statement )?;
whileStmt   -> "while" "(" expression ")" statement;
forStmt     -> "for" "(" ( varDecl | exprStmt | ; ) expression? ";" expression? ")" statement;
printStmt   -> "print" expression ";";
returnStmt  -> "return" expression? ";";
block       -> "{" declaration "}";
expression  -> assignment;
assignment  -> ( call "." )? IDENTIFIER "=" assignment | logic_or; 
logic_or    -> logic_and ( "or" logic_and )*;
logic_and   -> equality ( "and" equality )*;
equality    -> comparison ( ( "!=" | "==" ) comparison )*;
comparison  -> term ( ( ">" | ">=" | "<" | "<=" ) term )*;
term        -> factor ( ( "-" | "+" ) factor )*;
factor      -> unary ( ( "/" | "*" ) unary )*;
unary       -> ( "!" | "-" ) unary | call;
call        -> primary ( "(" arguements? ")" | "." IDENTIFIER )*;
arguements  -> expression ( "," expression )*;
primary     -> NUMBER | 
               STRING | 
               IDENTIFIER |
               "true" | 
               "false" | 
               "nil" | 
               "this" | 
               "super" "." IDENTIFIER | 
               "(" expression ")" ;
