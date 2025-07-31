require "./interpreter"
require "./expr"
require "./stmt"
require "./token"

class Resolver
  enum FunctionType
    NONE
    FUNCTION
    INITIALIZER
    METHOD
  end

  enum ClassType
    NONE
    CLASS
    SUBCLASS
  end

  @interpreter : Interpreter
  @scopes : Array(Hash(String, Bool)) = [] of Hash(String, Bool) 
  @current_function = FunctionType::NONE
  @current_class = ClassType::NONE

  def initialize(interpreter)
    @interpreter = interpreter
  end

  def visit_block_stmt(stmt : Stmt::Block)
    begin_scope
    #stmt.statements.each do |statement|
    #  resolve(statement)
    #end
    resolve(stmt.statements)
    end_scope

    nil
  end

  def visit_class_stmt(stmt : Stmt::Class)
    enclosing_class = @current_class
    @current_class = ClassType::CLASS

    declare(stmt.name)
    define(stmt.name)

    if !stmt.superclass.nil?
      if stmt.name.lexeme == stmt.superclass.try &.name.try &.lexeme
        Lox.error(stmt.superclass.try &.name, "A class can't inherit from itself.")
      end
      @current_class = ClassType::SUBCLASS
      resolve(stmt.superclass)
    end

    # should I just combine this with the previous conditional?
    if !stmt.superclass.nil?
      begin_scope
      @scopes.last["super"] = true
    end

    begin_scope
    @scopes.last["this"] = true 

    stmt.methods.each do |method|
      declaration = FunctionType::METHOD
      if method.name.lexeme == "init"
        declaration = FunctionType::INITIALIZER
      end
      resolve_function(method, declaration)
    end

    end_scope

    end_scope if !stmt.superclass.nil?

    @current_class = enclosing_class

    nil
  end

  def visit_expression_stmt(stmt : Stmt::Expression)
    resolve(stmt.expression)

    nil
  end


  def visit_function_stmt(stmt : Stmt::Function)
    declare(stmt.name)
    define(stmt.name)
    resolve_function(stmt, FunctionType::FUNCTION)

    nil
  end

  def visit_if_stmt(stmt : Stmt::If)
    resolve(stmt.condition)
    resolve(stmt.then_branch)
    resolve(stmt.else_branch) if !stmt.else_branch.nil?

    nil
  end

  def visit_print_stmt(stmt : Stmt::Print)
    resolve(stmt.expression)

    nil
  end

  def visit_return_stmt(stmt : Stmt::Return)
    if @current_function == FunctionType::NONE
      Lox.error(stmt.keyword, "Can't return from top-level code.")
    end

    if !stmt.value.nil?
      if @current_function == FunctionType::INITIALIZER
        Lox.error(stmt.keyword, "Can't return a value from an initializer.")
      end

      resolve(stmt.value) 
    end
    nil
  end

  def visit_var_stmt(stmt : Stmt::Var)
    declare(stmt.name)
    if !stmt.initializer.nil?
      resolve(stmt.initializer)
    end
    define(stmt.name)
    
    nil
  end

  def visit_while_stmt(stmt : Stmt::While)
    resolve(stmt.condition)
    resolve(stmt.body)

    nil
  end

  def visit_variable_expr(expr : Expr::Variable)
    # I'm running into a missing varioable issue, I shouldn't have to check
    #  if we have the key, but I think checking is covering an issue where
    #  some variables aren't getting set in the scopes.
    if !@scopes.empty? && @scopes.last.has_key?(expr.name.lexeme) && @scopes.last[expr.name.lexeme] == false 
      Lox.error(expr.name, "Can't read local local variable in its own initilaizer.")
    end

    resolve_local(expr, expr.name)

    nil
  end

  def visit_assign_expr(expr : Expr::Assign)
    resolve(expr.value)
    resolve_local(expr, expr.name)

    nil
  end

  def visit_binary_expr(expr : Expr::Binary)
    resolve(expr.left)
    resolve(expr.right)

    nil
  end

  def visit_call_expr(expr : Expr::Call)
    resolve(expr.callee)

    expr.arguments.each do |argument|
      resolve(argument)
    end

    nil
  end

  def visit_get_expr(expr : Expr::Get)
    resolve(expr.object)

    nil
  end

  def visit_grouping_expr(expr : Expr::Grouping)
    resolve(expr.expression)

    nil
  end

  def visit_literal_expr(expr : Expr::Literal)
    nil
  end

  def visit_logical_expr(expr : Expr::Logical)
    resolve(expr.left)
    resolve(expr.right)

    nil
  end

  def visit_set_expr(expr : Expr::Set)
    resolve(expr.value)
    resolve(expr.object)

    nil
  end

  def visit_super_expr(expr : Expr::Super)
    if @current_class == ClassType::NONE
      Lox.error(expr.keyword, "Can't use 'super' ouside of a class.")
    elsif @current_class != ClassType::SUBCLASS
      Lox.error(expr.keyword, "Can't use 'super' in a class with no superclass.")
    end

    resolve_local(expr, expr.keyword)

    nil
  end

  def visit_this_expr(expr : Expr::This)
    if @current_class == ClassType::NONE
      Lox.error(expr.keyword, "Can't use 'this' outside of a class.")
      return nil
    end

    resolve_local(expr, expr.keyword)
    
    nil
  end

  def visit_unary_expr(expr : Expr::Unary)
    resolve(expr.right)

    nil
  end

  def resolve(statements : Array(Stmt | Nil))
    statements.each do |statement|
      resolve(statement)
    end
  end

  def resolve(stmt_expr : Stmt | Expr | Nil)
    stmt_expr.try &.accept(self)
  end

  def resolve_function(function : Stmt::Function, type : FunctionType)
    enclosing_function = @current_function
    @current_function = type

    begin_scope
    function.params.each do |param|
      declare(param)
      define(param)
    end
    resolve(function.body)
    end_scope
    @current_function = enclosing_function
  end

  def begin_scope
    @scopes.push(Hash(String, Bool).new)
  end

  def end_scope
    @scopes.pop
  end

  def declare(name : Token)
    return if @scopes.empty?

    if @scopes.last.has_key?(name.lexeme)
      Lox.error(name, "Already a variable with this name in this scope.")
    end

    @scopes.last[name.lexeme] = false
  end

  def define(name : Token)
    return if @scopes.empty?

    @scopes.last[name.lexeme] = true
  end

  def resolve_local(expr, name)
    @scopes.each_with_index do |scope, i|
      if scope.has_key?(name.lexeme)
        @interpreter.resolve(expr, @scopes.size - 1 - i)
        return
      end
    end
  end
end
