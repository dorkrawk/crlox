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
end
