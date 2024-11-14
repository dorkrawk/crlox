require "./token"
require "./token_type"
require "./expr"

class AstPrinter
  def print(expr)
    expr.accept(self)
  end

  def visit_binary_expr(expr)
    parenthesize(expr.operator.lexeme, expr.left, expr.right)
  end

  def visit_grouping_expr(expr)
    parenthesize("group", expr.expression)
  end

  def visit_literal_expr(expr)
    return expr.value.to_s if expr.value != nil
    "nil"
  end

  def visit_unary_expr(expr)
    parenthesize(expr.operator.lexeme, expr.right)
  end

  def parenthesize(name, *exprs)
    "(#{name} #{exprs.map { |expr| expr.accept(self) }.join(" ")})"
  end

  def main()
    expression = Expr::Binary.new(
      Expr::Unary.new(
        Token.new(TokenType::MINUS, "-", nil, 1),
        Expr::Literal.new(123)
      ),
      Token.new(TokenType::STAR, "*", nil, 1),
      Expr::Grouping.new(
        Expr::Literal.new(45.67)
      )
    )

    puts AstPrinter.new.print(expression)
  end
end

AstPrinter.new.main
