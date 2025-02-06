abstract class Stmt
  abstract def accept(visitor : StmtVisitor)

  class Block < Stmt
    getter :statements

    def initialize(statements : Array(Stmt | Nil))
      @statements = statements
    end

    def accept(visitor)
      visitor.visit_block_stmt(self)
    end
  end

  class Expression < Stmt
    getter :expression

    def initialize(expression : Expr)
      @expression = expression
    end

    def accept(visitor)
      visitor.visit_expression_stmt(self)
    end
  end

  class If < Stmt
    getter :condition
    getter :then_branch
    getter :else_branch

    def initialize(condition : Expr, then_branch : Stmt, else_branch : Stmt | Nil)
      @condition = condition
      @then_branch = then_branch
      @else_branch = else_branch
    end

    def accept(visitor)
      visitor.visit_if_stmt(self)
    end
  end

  class Print < Stmt
    getter :expression

    def initialize(expression : Expr)
      @expression = expression
    end

    def accept(visitor)
      visitor.visit_print_stmt(self)
    end
  end

  class Var < Stmt
    getter :name
    getter :initializer

    def initialize(name : Token, initializer : Expr | Nil)
      @name = name
      @initializer = initializer
    end

    def accept(visitor)
      visitor.visit_var_stmt(self)
    end
  end

  class While < Stmt
    getter :condition
    getter :body

    def initialize(condition : Expr, body : Stmt)
      @condition = condition
      @body = body
    end

    def accept(visitor)
      visitor.visit_while_stmt(self)
    end
  end
end
