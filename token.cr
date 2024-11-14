class Token
  KEYWORDS = {
    "and"    => TokenType::AND,
    "class"  => TokenType::CLASS,
    "else"   => TokenType::ELSE,
    "false"  => TokenType::FALSE,
    "for"    => TokenType::FOR,
    "fun"    => TokenType::FUN,
    "if"     => TokenType::IF,
    "nil"    => TokenType::NIL,
    "or"     => TokenType::OR,
    "print"  => TokenType::PRINT,
    "return" => TokenType::RETURN,
    "super"  => TokenType::SUPER,
    "this"   => TokenType::THIS,
    "true"   => TokenType::TRUE,
    "var"    => TokenType::VAR,
    "while"  => TokenType::WHILE,
  }

  getter :type, :lexeme, :literal, :line

  def initialize(@type : TokenType, @lexeme : String, @literal : String | Nil, @line : Int32)
  end

  def initialize(@type : TokenType, @lexeme : String, @literal : Float64 | Nil, @line : Int32)
  end

  def to_s
    "<#{@type}, #{@lexeme}, #{@literal}>"
  end
end
