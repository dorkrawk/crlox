require "./runtime_error"

class Interpreter
  # include Expr::Visitor

  def visit_literal_expr(expr : Expr::Literal)
    expr.value
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

  def evaluate(expr : Expr)
    expr.accept(self)
  end

  def interpret(expr : Expr)
    begin
      value = evaluate(expr)
      puts stringify(value)
    rescue e : LoxRuntimeError
      Lox.runtime_error(e.token, e.message.to_s)
      nil
    end
  end

  def stringify(value : Object)
    return "nil" if value.nil?
    value.to_s
  end
end

