abstract class Expr
  abstract def accept(visitor : ExprVisitor)

  class Assign < Expr
    getter :name
    getter :value

    def initialize(name : Token, value : Expr)
      @name = name
      @value = value
    end

    def accept(visitor)
      visitor.visit_assign_expr(self)
    end
  end

  class Binary < Expr
    getter :left
    getter :operator
    getter :right

    def initialize(left : Expr, operator : Token, right : Expr)
      @left = left
      @operator = operator
      @right = right
    end

    def accept(visitor)
      visitor.visit_binary_expr(self)
    end
  end

  class Grouping < Expr
    getter :expression

    def initialize(expression : Expr)
      @expression = expression
    end

    def accept(visitor)
      visitor.visit_grouping_expr(self)
    end
  end

  class Literal < Expr
    getter :value

    def initialize(value : Bool | Nil | Float64 | String)
      @value = value
    end

    def accept(visitor)
      visitor.visit_literal_expr(self)
    end
  end

  class Logical < Expr
    getter :left
    getter :operator
    getter :right

    def initialize(left : Expr, operator : Token, right : Expr)
      @left = left
      @operator = operator
      @right = right
    end

    def accept(visitor)
      visitor.visit_logical_expr(self)
    end
  end

  class Set < Expr
    getter :object
    getter :name
    getter :value

    def initialize(object : Expr, name : Token, value : Expr)
      @object = object
      @name = name
      @value = value
    end

    def accept(visitor)
      visitor.visit_set_expr(self)
    end
  end

  class Super < Expr
    getter :keyword
    getter :method

    def initialize(keyword : Token, method : Token)
      @keyword = keyword
      @method = method
    end

    def accept(visitor)
      visitor.visit_super_expr(self)
    end
  end

  class This < Expr
    getter :keyword

    def initialize(keyword : Token)
      @keyword = keyword
    end

    def accept(visitor)
      visitor.visit_this_expr(self)
    end
  end

  class Unary < Expr
    getter :operator
    getter :right

    def initialize(operator : Token, right : Expr)
      @operator = operator
      @right = right
    end

    def accept(visitor)
      visitor.visit_unary_expr(self)
    end
  end

  class Call < Expr
    getter :callee
    getter :paren
    getter :arguments

    def initialize(callee : Expr, paren : Token, arguments : Array(Expr))
      @callee = callee
      @paren = paren
      @arguments = arguments
    end

    def accept(visitor)
      visitor.visit_call_expr(self)
    end
  end

  class Get < Expr
    getter :object
    getter :name

    def initialize(object : Expr, name : Token)
      @object = object
      @name = name
    end

    def accept(visitor)
      visitor.visit_get_expr(self)
    end
  end

  class Variable < Expr
    getter :name

    def initialize(name : Token)
      @name = name
    end

    def accept(visitor)
      visitor.visit_variable_expr(self)
    end
  end
end
