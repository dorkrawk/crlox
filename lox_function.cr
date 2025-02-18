require "./lox_callable"
require "./stmt"
require "./environment"
require "./return"

class LoxFunction < LoxCallable
  def initialize(declaration : Stmt::Function, closure : Environment)
    @closure = closure
    @declaration = declaration
  end
  
  def call(interpreter, arguments)
    environment = Environment.new(@closure)
    @declaration.params.each_with_index do |param, i|
      environment.define(param.lexeme, arguments[i])
    end

    begin
      interpreter.execute_block(@declaration.body, environment)
    rescue return_value : Return
      return return_value.value
    end
    nil
  end

  def arity
    @declaration.params.size
  end

  def to_s
    "<fn #{declaration.name.lexeme}>"
  end
end
