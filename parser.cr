require "./token_type"
require "./token"
require "./expr"
require "./stmt"

class Parser
  class ParseError < Exception; end

  getter :tokens
  getter :current

  def initialize(tokens : Array(Token))
    @tokens = tokens
    @current = 0
  end

  def parse
    # Right now we don't want to return nil if there's an error because Crystal doesn't want
    # to handle Expr|Nil for the AstPrinter.
    #
    # begin
    #   return expression
    # rescue ex : ParseError
    #   return
    # end
    statements = [] of Stmt | Nil
    while !is_at_end?
      statements << declaration
    end

    statements
  end

  def declaration
    return var_declaration if match(TokenType::VAR)
    return statement
  rescue e : ParseError
    synchronize
    return nil
  end

  def statement
    return if_statement if match(TokenType::IF)
    return print_statement if match(TokenType::PRINT)
    return Stmt::Block.new(block) if match(TokenType::LEFT_BRACE)

    expression_statement
  end

  def if_statement
    consume(TokenType::LEFT_PAREN, "Expect '(' after 'if'.")
    condition = expression
    consume(TokenType::RIGHT_PAREN, "Expect ')' after if condition.")

    then_branch = statement
    else_branch = nil
    else_branch = statement if match(TokenType::ELSE) # else is bound to the nearest if statement

    Stmt::If.new(condition, then_branch, else_branch)
  end

  def print_statement
    value = expression
    consume(TokenType::SEMICOLON, "Expect ';' after value.")

    Stmt::Print.new(value)
  end

  def block
    statements = [] of Stmt | Nil
    while !check(TokenType::RIGHT_BRACE) && !is_at_end?
      statements << declaration
    end
    consume(TokenType::RIGHT_BRACE, "Expect '}' after block.")
    
    statements
  end

  def var_declaration
    name = consume(TokenType::IDENTIFIER, "Expect variable name.")

    initializer = nil
    initializer = expression if match(TokenType::EQUAL)

    consume(TokenType::SEMICOLON, "Expect ';' after variable declaration.")
    Stmt::Var.new(name, initializer)
  end

  def expression_statement
    expr = expression
    consume(TokenType::SEMICOLON, "Expect ';' after value.")

    Stmt::Expression.new(expr)
  end

  def expression
    assignment
  end

  def assignment
    expr = or

    if match(TokenType::EQUAL)
      equals = previous
      value = assignment
      if expr.is_a?(Expr::Variable)
        name = expr.name
        return Expr::Assign.new(name, value)
      end

      raise error(equals, "Invalid assignment target.")
    end

    expr
  end

  def or
    expr = and

    while match(TokenType::OR)
      operator = previous
      right = and
      expr = Expr::Logical.new(expr, operator, right)
    end

    expr
  end

  def and
    expr = equality

    while match(TokenType::AND)
      operator = previous
      right = equality
      expr = Expr::Logical.new(expr, operator, right)
    end

    expr
  end

  def equality
    expr = comparison

    while match(TokenType::BANG_EQUAL, TokenType::EQUAL_EQUAL)
      operator = previous
      right = comparison
      expr = Expr::Binary.new(expr, operator, right)
    end
    expr
  end

  def comparison
    expr = term

    while match(TokenType::GREATER, TokenType::GREATER_EQUAL, TokenType::LESS, TokenType::LESS_EQUAL)
      operator = previous
      right = term
      expr = Expr::Binary.new(expr, operator, right)
    end
    expr
  end

  def term
    expr = factor

    while match(TokenType::MINUS, TokenType::PLUS)
      operator = previous
      right = factor
      expr = Expr::Binary.new(expr, operator, right)
    end
    expr
  end

  def factor
    expr = unary

    while match(TokenType::SLASH, TokenType::STAR)
      operator = previous
      right = unary
      expr = Expr::Binary.new(expr, operator, right)
    end
    expr
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

    return Expr::Variable.new(previous) if match(TokenType::IDENTIFIER)

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
    return false if is_at_end?
    peek.type == type
  end

  def advance
    @current += 1 unless is_at_end?
    previous
  end

  def is_at_end?
    peek.type == TokenType::EOF
  end

  def peek
    tokens[@current]
  end

  def previous
    tokens[@current - 1]
  end
end
