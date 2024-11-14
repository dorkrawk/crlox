require "./token_type"
require "./token"
require "./expr"

class Parser

  class ParseError < Exception; end;

  getter :tokens
  getter :current

  def initialize(tokens : Array(Token))
    @tokens = tokens
    @current = 0
  end

  def parse
    begin
      return expression
    rescue ex : ParseError
      return
    end
  end

  def expression
    equality
  end

  def equality
    expr = comparison

    while match(TokenType::BANG_EQUAL, TokenType::EQUAL_EQUAL)
      operator = previous
      right = comparison
      expr = Expr::Binary.new(exp, operator, right)
    end
    expr
  end

  def comparison
    expr = term

    while match(TokenType::GREATER, TokenType::GREATER_EQUAL, TokenType::LESS, TokenType::LESS_EQUAL)
      operator = previous
      right = term
      expr = Expr::Binary.new(exp, operator, right)
    end
  end

  def term
    expr = factor

    while match(TokenType::MINUS, TokenType::PLUS)
      operator = previous
      right = factor
      expr = Expr::Binary.new(expr, operator, right)
    end
  end

  def factor
    expr = unary

    while match(TokenType::SLASH, TokenType::STAR)
      operator = previous
      right = unary
      expr = Expr::Binary.new(expr, operator, right)
    end
  end

  def unary
    if match(TokenType::BANG, TokenType::MINUS)
      operator = previous
      right = unary
      return Expr::Unary.new(operator, right)
    end

    primary
  end

  def primary
    return Expr::Literal.new(false) if match(TokenType::FALSE)
    return Expr::Literal.new(true) if match(TokenType::TRUE)
    return Expr::Literal.new(nil) if match(TokenType::NIL)

    if match(TokenType::NUMBER, TokenType::STRING)
      return Expr::Literal.new(previous.literal)
    end

    if match(TokenType::LEFT_PAREN)
      expr = expression
      consume(TokenType::RIGHT_PAREN, "Expect ')' after expression.")
      return Expr::Grouping.new(expr)
    end

    raise error(peek, "Expect expression.")
  end

  def consume(type : TokenType, message : String)
    return advance if check(type)

    raise error(peek, message)
  end

  def error(token : Token, message : String)
    Lox.error(token, message)
    ParseError.new
  end

  def synchronize
    advance

    while !is_at_end?
      return if previous.type == TokenType::SEMICOLON

      case peek.type
      when TokenType::CLASS, TokenType::FUN, TokenType::VAR, TokenType::FOR, TokenType::IF, TokenType::WHILE,
        TokenType::PRINT, TokenType::RETURN
        return
      end
    end

    advance
  end

  def match(*types : TokenType)
    types.each do |type|
      if check(type)
        advance
        return true
      end
    end

    false
  end

  def check(type : TokenType)
    return false if is_at_end
    peek.type == type
  end

  def advance
    @current += 1 unless is_at_end
    previous
  end

  def is_at_end
    peek.type == TokenType::EOF
  end

  def peek
    tokens[@current]
  end

  def previous
    tokens[@current - 1]
  end
end
