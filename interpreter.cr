require "./runtime_error"
require "./return"
require "./environment"
require "./lox_callable"
require "./lox_function"

class Interpreter
  GLOBALS = Environment.new
  @environment = GLOBALS


  CLOCK_NATIVE_FN = Class.new(LoxCallable) do
      def arity
        0
      end

      def call(interpreter, arguements)
        Time.utc.to_unix
      end

      def to_s
        "<native fn>"
      end
    end

  def initializer
    GLOBALS.define("clock", CLOCK_NATIVE_FN)
  end

  def visit_literal_expr(expr : Expr::Literal)
    expr.value
  end

  def visit_logical_expr(expr : Expr::Logical)
    left = evaluate(expr.left)

    # handling early returns for OR and AND
    if expr.operator.type == TokenType::OR
      return left if is_truthy?(left)
    else 
      return left if !is_truthy?(left)
    end

    return evaluate(expr.right)
  end

  def visit_grouping_expr(expr : Expr::Grouping)
    evaluate(expr.expression)
  end

  def visit_unary_expr(expr : Expr::Unary)
    right = evaluate(expr.right)
    case expr.operator.type
    when TokenType::BANG
      !is_truthy?(right)
    when TokenType::MINUS
      check_number_operand(expr.operator, right)
      -right.as(Float64)
    else
      raise "Unknown unary operator: #{expr.operator.type}"
    end
  end

  def visit_binary_expr(expr : Expr::Binary)
    left = evaluate(expr.left)
    right = evaluate(expr.right)
    case expr.operator.type
    when TokenType::MINUS
      check_number_operand(expr.operator, right)
      left.as(Float64) - right.as(Float64)
    when TokenType::SLASH
      check_number_operand(expr.operator, right)
      left.as(Float64) / right.as(Float64)
    when TokenType::STAR
      check_number_operand(expr.operator, right)
      left.as(Float64) * right.as(Float64)
    when TokenType::PLUS
      if left.is_a?(String) && right.is_a?(String)
        left + right
      elsif left.is_a?(Float64) && right.is_a?(Float64)
        check_number_operand(expr.operator, left)
        check_number_operand(expr.operator, right)
        left.as(Float64) + right.as(Float64)
      else
        raise LoxRuntimeError.new(expr.operator, "Operands must be two numbers or two strings. Got #{left.class} and #{right.class}.")
      end
    when TokenType::GREATER
      check_number_operand(expr.operator, left)
      check_number_operand(expr.operator, right)
      left.as(Float64) > right.as(Float64)
    when TokenType::GREATER_EQUAL
      check_number_operand(expr.operator, left)
      check_number_operand(expr.operator, right)
      left.as(Float64) >= right.as(Float64)
    when TokenType::LESS
      check_number_operand(expr.operator, left)
      check_number_operand(expr.operator, right)
      left.as(Float64) < right.as(Float64)
    when TokenType::LESS_EQUAL
      check_number_operand(expr.operator, left)
      check_number_operand(expr.operator, right)
      left.as(Float64) <= right.as(Float64)
    when TokenType::BANG_EQUAL
      !is_equal?(left, right)
    when TokenType::EQUAL_EQUAL
      is_equal?(left, right)
    else
      raise "Unknown binary operator: #{expr.operator.type}"
    end
  end

  def visit_call_expr(expr : Expr::Call)
    callee = evaluate(expr.callee)

    arguments = [] of (String | Bool | Nil | Float64 | String | LoxCallable)
    expr.arguments.each do |argument|
      arguments << evaluate(argument)
    end

    if !callee.is_a?(LoxCallable)
      raise LoxRuntimeError.new(expr.paren, "Can only call functions and classes.")
    end

    function = callee # need to cast this as a LoxCallable type?

    if arguments.size != function.arity
      raise LoxRuntimeError.new(expr.paren, "Expected #{function.arity} arguments but got #{arguments.size}.")
    end

    function.call(self, arguments)
  end

  def visit_expression_stmt(stmt : Stmt::Expression)
    evaluate(stmt.expression)
  end

  def visit_function_stmt(stmt : Stmt::Function)
    function = LoxFunction.new(stmt, @environment)
    @environment.define(stmt.name.lexeme, function)
    nil
  end

  def visit_if_stmt(stmt : Stmt::If)
    if is_truthy?(evaluate(stmt.condition))
      execute(stmt.then_branch)
    elsif !stmt.else_branch.nil?
      execute(stmt.else_branch)
    end
    nil
  end

  def visit_while_stmt(stmt : Stmt::While)
    while is_truthy?(evaluate(stmt.condition))
      execute(stmt.body)
    end
    nil
  end

  def visit_print_stmt(stmt : Stmt::Print)
    value = evaluate(stmt.expression)
    puts value
    nil
  end

  def visit_return_stmt(stmt : Stmt::Return)
    value = nil
    value = evaluate(stmt.value) if !stmt.value.nil?

    # using an exception to unwind the interpreter back to the code that
    #   began executing the body.
    raise Return.new(value) # still need to implement Return
  end

  def visit_block_stmt(stmt : Stmt::Block)
    execute_block(stmt.statements, Environment.new(@environment))
    nil
  end

  def execute_block(statements : Array(Stmt | Nil), environment : Environment)
    previous = @environment
    begin
      @environment = environment
      statements.each do |statement|
        execute(statement)
      end
    ensure
      @environment = previous
    end
  end

  def visit_var_stmt(stmt : Stmt::Var)
    value = nil
    value = evaluate(stmt.initializer) if stmt.initializer
    @environment.define(stmt.name.lexeme, value)
    nil
  end

  def visit_assign_expr(expr : Expr::Assign)
    value = evaluate(expr.value)
    @environment.assign(expr.name, value)
    value
  end

  def visit_variable_expr(expr : Expr::Variable)
    @environment.get(expr.name)
  end

  def is_truthy?(value)
    return false if value.nil?
    return !!value if value.is_a?(Bool)
    true
  end

  def is_equal?(a, b)
    a == b
  end

  def check_number_operand(operator : Token, operand : Object)
    if operand.is_a?(Float64)
      return true
    else
      raise LoxRuntimeError.new(operator, "Operand must be a number. Got #{operand.class}.")
    end
  end

  def evaluate(expr : Expr | Nil)
    return nil if expr.nil?
    expr.accept(self)
  end

  def interpret(statements : Array(Stmt | Nil))
    begin
      last_value = nil
      statements.each do |statement|
        last_value = execute(statement)
      end
      last_value
    rescue e : LoxRuntimeError
      Lox.runtime_error(e.token, e.message.to_s)
      nil
    end
  end

  def execute(stmt : Stmt | Nil)
    return if stmt.nil?
    stmt.accept(self)
  end

  def stringify(value : Object)
    return "nil" if value.nil?
    value.to_s
  end
end
