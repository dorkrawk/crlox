require "./runtime_error"
require "./return"
require "./environment"
require "./lox_callable"
require "./lox_function"
require "./lox_class.cr"

class Interpreter
  GLOBALS = Environment.new
  @environment = GLOBALS
  @locals = Hash(Expr, Int32).new


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

  def visit_set_expr(expr : Expr::Set)
    object = evaluate(expr.object)

    if !object.is_a? LoxInstance
      raise LoxRuntimeError.new(expr.name, "Only instances can have fields.")
    end

    value = evaluate(expr.value)

    object.set(expr.name, value)

    value
  end

  def visit_super_expr(expr : Expr::Super)
    distance = @locals[expr]
    superclass = @environment.try &.get_at(distance, "super")

    object = @environment.try &.get_at(distance - 1, "this")

    method = superclass.as(LoxClass).find_method(expr.method.lexeme)

    if method.nil?
      raise LoxRuntimeError.new(expr.method, "Undefined property #{expr.method.lexeme}.")
    end

    method.bind(object.as(LoxInstance))
  end

  def visit_this_expr(expr : Expr::This)
    look_up_variable(expr.keyword, expr)
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

    arguments = [] of (String | Bool | Nil | Float64 | String | LoxCallable | LoxClass | LoxInstance)
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

  def visit_get_expr(expr : Expr::Get)
    object = evaluate(expr.object)
    if object.is_a? LoxInstance
      return object.try &.get(expr.name)
    end

    raise LoxRuntimeError.new(expr.name, "Only instances have properties.")
  end

  def visit_expression_stmt(stmt : Stmt::Expression)
    evaluate(stmt.expression)
  end

  def visit_function_stmt(stmt : Stmt::Function)
    function = LoxFunction.new(stmt, @environment.as(Environment), false)
    @environment.try &.define(stmt.name.lexeme, function)
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

  def visit_class_stmt(stmt : Stmt::Class)
    superclass = nil
    if !stmt.superclass.nil?
      superclass = evaluate(stmt.superclass)
      if !superclass.is_a?(LoxClass)
        # this isn't great... figure out better nil handling
        superclass_name = stmt.superclass.try &.name || Token.new(TokenType::CLASS,"","", 0)
        raise LoxRuntimeError.new(superclass_name, "Superclass must be a class.")
      end
    end

    @environment.try &.define(stmt.name.lexeme, nil)

    if !stmt.superclass.nil?
      @environment = Environment.new(@environment)
      @environment.try &.define("super", superclass.as(LoxClass))
    end

    methods = {} of String => LoxFunction
    stmt.methods.each do |method|
      is_initializer = method.name.lexeme == "init"
      function = LoxFunction.new(method, @environment.as(Environment), is_initializer)
      methods[method.name.lexeme] = function
    end

    klass = LoxClass.new(stmt.name.lexeme, superclass, methods)

    if !superclass.nil?
      # ewwww this is aweful
      @environment = @environment.try &.enclosing.as(Environment)
    end

    @environment.try &.assign(stmt.name, klass)

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
    @environment.try &.define(stmt.name.lexeme, value)
    nil
  end

  def visit_assign_expr(expr : Expr::Assign)
    value = evaluate(expr.value)
    
    distance = @locals.has_key?(expr) ? @locals[expr] : nil
    if !distance.nil?
      @environment.try &.assign_at(distance, expr.name, value)
    else
      GLOBALS.assign(expr.name, value)
    end

    value
  end

  def visit_variable_expr(expr : Expr::Variable)
    look_up_variable(expr.name, expr)
  end

  def look_up_variable(name : Token, expr : Expr)
    distance = @locals.has_key?(expr) ? @locals[expr] : nil
    if !distance.nil?
      @environment.try &.get_at(distance, name.lexeme)
    else
      GLOBALS.get(name)
    end
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

  def resolve(expr : Expr, depth : Int32)
    @locals[expr] = depth
  end

  def stringify(value : Object)
    return "nil" if value.nil?
    value.to_s
  end
end
