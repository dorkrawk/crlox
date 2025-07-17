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
    return class_declaration if match(TokenType::CLASS)
    return function("function") if match(TokenType::FUN)
    return var_declaration if match(TokenType::VAR)
    return statement
  rescue e : ParseError
    synchronize
    return nil
  end

  def class_declaration
    name = consume(TokenType::IDENTIFIER, "Expect class name.")

    superclass = nil
    if match(TokenType::LESS)
      consume(TokenType::IDENTIFIER, "Expect superclass name.")
      superclass = Expr::Variable.new(previous)
    end
    consume(TokenType::LEFT_BRACE, "Expect '{' before class body.")

    methods = [] of Stmt::Function

    while !check(TokenType::RIGHT_BRACE) && !is_at_end?
      methods << function("method")
    end

    consume(TokenType::RIGHT_BRACE, "Expect '}' after class body.")

    return Stmt::Class.new(name, superclass, methods)
  end

  def statement
    return for_statement if match(TokenType::FOR)
    return if_statement if match(TokenType::IF)
    return print_statement if match(TokenType::PRINT)
    return return_statement if match(TokenType::RETURN)
    return while_statement if match(TokenType::WHILE)
    return Stmt::Block.new(block) if match(TokenType::LEFT_BRACE)

    expression_statement
  end

  def for_statement
    # for (var i = 0; i < 10; i = i + 1)
    consume(TokenType::LEFT_PAREN, "Expect '(' after 'for'.")

    initializer = nil
    
    if match(TokenType::SEMICOLON) # omitted initializer
      initializer = nil
    elsif match(TokenType::VAR) # iterator declaration
      initializer = var_declaration
    else
      initializer = expression_statement
    end
  
    condition = nil

    if !check(TokenType::SEMICOLON)
      condition = expression
    end
    consume(TokenType::SEMICOLON, "Expect ';' after look condition.")

    increment = nil

    if !check(TokenType::RIGHT_PAREN)
      increment = expression
    end
    consume(TokenType::RIGHT_PAREN, "Expect ')' after for clauses.")

    body = statement

    if !increment.nil?
      inc_stmt_array : Array(Stmt) = [body, Stmt::Expression.new(increment)].as(Array(Stmt))
      body_with_increment = Array(Stmt | Nil).new
      body_with_increment.concat(inc_stmt_array)
      body = Stmt::Block.new(body_with_increment)
    end
    # { body; i = i + 1; }

    condition = Expr::Literal.new(true) if condition.nil?

    body = Stmt::While.new(condition, body)
    # while(i < 10) {
    #   body;
    #   i = i + 1;
    # }
    
    if !initializer.nil?
      stmt_array : Array(Stmt) = [initializer, body]
      body_with_initializer = Array(Stmt | Nil).new
      body_with_initializer.concat(stmt_array)

      body = Stmt::Block.new(body_with_initializer)
    end
    # var i = 0;
    # while(i < 10) {
    #   body;
    #   i = i + 1;
    # }
    #

    puts "*********** for loop rewrite"

    return body
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

  def while_statement
    consume(TokenType::LEFT_PAREN, "Expect '(' after 'while.'")
    condition = expression
    consume(TokenType::RIGHT_PAREN, "Expect ')' after condition.")
    body = statement

    Stmt::While.new(condition, body)
  end

  def print_statement
    value = expression
    consume(TokenType::SEMICOLON, "Expect ';' after value.")

    Stmt::Print.new(value)
  end

  def return_statement
    keyword = previous
    value = nil

    if !check(TokenType::SEMICOLON)
      value = expression
    end

    consume(TokenType::SEMICOLON, "Expect ';' after return value.")

    return Stmt::Return.new(keyword, value)
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

  def function(kind)
    name = consume(TokenType::IDENTIFIER, "Expect #{kind} name.")
    consume(TokenType::LEFT_PAREN, "Expect '(' after #{kind} name.")
    parameters = [] of Token
    if !check(TokenType::RIGHT_PAREN)
      loop do
        if parameters.size >= 255
          error(peek, "Can't have more than 255 parameters.")
        end
        parameters << consume(TokenType::IDENTIFIER, "Expect parameter name.")
        break if !match(TokenType::COMMA)
      end
    end
    consume(TokenType::RIGHT_PAREN, "Expect ')' after parameters.")
    consume(TokenType::LEFT_BRACE, "Expect '{' before #{kind} body.")

    body = block

    Stmt::Function.new(name, parameters, body)
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
      elsif expr.is_a? Expr::Get
        get = expr
        return Expr::Set.new(get.object, get.name, value)
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

    call
  end

  def call
    expr = primary

    while true   # there's a reason for doing this "while true" style...
      if match(TokenType::LEFT_PAREN)
        expr = finish_call(expr)
      elsif match(TokenType::DOT)
        name = consume(TokenType::IDENTIFIER, "Expect property name after '.'.")
        expr = Expr::Get.new(expr, name)
      else 
        break
      end
    end

    expr
  end

  def finish_call(callee)
    arguments = [] of Expr

    if !check(TokenType::RIGHT_PAREN)
      loop do
        if arguments.size >= 255
          error(peek, "Can't have more than 255 arguments.")
        end
        arguments << expression
        break if !match(TokenType::COMMA)
      end
    end

    paren = consume(TokenType::RIGHT_PAREN, "Expect ')' after arguments.")
    
    Expr::Call.new(callee, paren, arguments)
  end

  def primary
    return Expr::Literal.new(false) if match(TokenType::FALSE)
    return Expr::Literal.new(true) if match(TokenType::TRUE)
    return Expr::Literal.new(nil) if match(TokenType::NIL)

    if match(TokenType::NUMBER, TokenType::STRING)
      return Expr::Literal.new(previous.literal)
    end

    if match(TokenType::SUPER)
      keyword = previous
      consume(TokenType::DOT, "Expect ',' after 'super'.")
      method = consume(TokenType::IDENTIFIER, "Expect superclass method name.")
      return Expr::Super.new(keyword, method)
    end

    return Expr::This.new(previous) if match(TokenType::THIS)

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
